#/bin/bash
###########################
# Author : DJERBI Florian
# Object : Run full backup and incremental backup for all mariadb
# Creation Date : 01/04/2024
# Modification Date : 03/18/2024
###########################

#
# VARIABLES
#
source variable
log_file=${folder_backup}/backup.log
last_log_file=${folder_backup}/backup_last.log

#
# FUNCTIONS
#

function msg(){
    datetime_now=$(date +"%D %T")
    echo "[${datetime_now}] : $1" >> ${last_log_file}
}

function init_script(){
    if [ -n ${folder_backup} ] && [ -n ${log_file} ] && [ -n ${last_log_file} ];then
        mkdir -p ${folder_backup}
        touch ${log_file}
	touch ${last_log_file}
    fi
}

function check_last_full(){
    number_full_backup=$(find ${folder_backup} -type f -name ${backup_full_name}-* |wc -l)
    name_full_backup=$(find ${folder_backup} -type f -name ${backup_full_name}-* |sort -n |tail -n 1)
    time_last_full=$(find ${folder_backup} -type f -name ${backup_full_name}-* -mtime -${incremental_day})
    if [[ ${number_full_backup} -eq 0 ]] || [[ -z ${time_last_full} ]];then
        msg "Run first full backup !"
        sleep 3
	backup_full
    else
        msg "Run inc backup !"
        sleep 3
        backup_inc
    fi
}

function backup_full(){
    last_full_number=$(find ${folder_backup} -type f -name ${backup_full_name}-* |sort -n |tail -n 1 |cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
    last_full_number=$((${last_full_number}+1))
    target_dir="${folder_backup}/${backup_full_name}-${last_full_number}"
    mariabackup --backup --user=${db_user} --password=${db_password} --target-dir=${target_dir} >> ${last_log_file} 2>&1
    msg "Run tar gz last backup ${backup_full_name}-${last_full_number}"
    tar -cvzf ${target_dir}.tar.gz -P ${target_dir} >> ${last_log_file}
}

function backup_inc(){
    last_full_number=$(find ${folder_backup} -type f -name ${backup_full_name}-* |sort -n |tail -n 1 |cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
    last_inc_name=$(find ${folder_backup} -type f -name ${backup_inc_name}-${last_full_number}* -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    last_inc_number=$(echo "${last_inc_name}" |cut -f4 -d/ |cut -f3 -d- |cut -f1 -d.)
    new_inc_number=$((${last_inc_number}+1))
    target_dir="${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number}"
    if [[ -z ${last_inc_name} ]];then
	incremental_basedir="${folder_backup}/${backup_full_name}-${last_full_number}"
        msg "Run incremental backup by last full !"
    else
	incremental_basedir="${folder_backup}/${backup_inc_name}-${last_full_number}-${last_inc_number}"
        msg "Run incremental backup by last incremental !"
    fi
    mariabackup --backup --user=${db_user} --password=${db_password} --incremental-basedir=${incremental_basedir} --target-dir=${target_dir} >> ${last_log_file} 2>&1
    tar -cvzf ${target_dir}.tar.gz -P ${target_dir} >> ${last_log_file}
}

function check_old_backup(){
    count_backup=$(find ${folder_backup}/* -maxdepth 0 -type d |wc -l)
    if [ ${count_backup} -gt 1 ]; then
        old_backup_name=$(find /opt/mariadb-backup/ -mindepth 1 -maxdepth 1 -type d |sort -r |tail -n 1)
        if [[ ! -z ${old_backup_name} ]];then
            rm -rf ${old_backup_name}
        fi
    fi
    count_full_backup=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz| wc -l)
    if [ ${count_full_backup} -gt ${full_retention} ]; then
        old_full_number=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |head -n 1 |cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
	if [ -n ${folder_backup} ] && [ -n ${backup_full_name} ] && [ -n ${old_full_number} ] ;then
	    rm -rf ${folder_backup}/${backup_full_name}-${old_full_number}*
	    rm -rf ${folder_backup}/${backup_inc_name}-${old_full_number}*
            msg "Delete full and incremental backup ${old_full_number}"
	fi
    fi
}

function sync_s3(){
    if [ ${s3_backup} == "yes" ];then
	msg "Sync backup into S3"
	aws s3 sync --exclude "*" --include "*.tar.gz" --include "*.log" ${folder_backup} s3://${s3_name}/${s3_path} >> ${last_log_file}
        s3_retention_date=$(date +"%Y-%m-%d %T" -d "-${s3_retention_day} days")
	s3_old_backup=$(aws s3 ls --recursive s3://h2o-backup-mysql/lab1.ta-info.net/ |grep "${backup_full_name}" |grep gz |awk -v prev="${s3_retention_date}" '$0 < prev {print $4}') 
	s3_old_full_number=$(echo ${s3_old_backup} |cut -f2 -d/|cut -f2 -d- |cut -f1 -d.)
	if [ -n "${s3_old_full_number}" ];then
	    msg "Delete ${s3_number_old_backup} old backup in s3"
	    aws s3 ls --recursive s3://${s3_name}/${s3_path}/ |grep "${s3_path}/${backup_full_name}-${s3_old_full_number}" |awk '{print $4}' |xargs -n1 'KEY' aws s3 rm s3://${s3_name}/'KEY' >> ${last_log_file}
	    aws s3 ls --recursive s3://${s3_name}/${s3_path}/ |grep "${s3_path}/${backup_inc_name}-${s3_old_full_number}" |awk '{print $4}' |xargs -n1 'KEY' aws s3 rm s3://${s3_name}/'KEY' >> ${last_log_file}
	fi
    fi
}

function last_log_in_log(){
    cat ${last_log_file} >> ${log_file}
}

function main(){
    datetime_now=$(date +"%D %T")
    echo  "[${datetime_now}] : Run script backup mariadb" > ${last_log_file}
    init_script "$@"
    while test $# -gt 0; do
        param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        case "$param" in
	   full | f)
                backup_full "$@"
                check_old_backup "$@"
                sync_s3 "$@"
                last_log_in_log "$@"
		exit 0
		;;
	   inc |incremental | i)
                backup_inc "$@"
                check_old_backup "$@"
                sync_s3 "$@"
                last_log_in_log "$@"
		exit 0
		;;
	    -* | --* | *)
	        echo "Nothing"
		exit 0
	esac
	shift
    done
    if [[ $# -eq 0 ]];then
        check_all "$@"
    fi
}

function check_all(){
    echo "Normal run"
    datetime_now=$(date +"%D %T")
    echo  "[${datetime_now}] : Run script backup mariadb" > ${last_log_file}
    init_script "$@"
    check_last_full "$@"
    check_old_backup "$@"
    sync_s3 "$@"
    last_log_in_log "$@"
}

main "$@"
