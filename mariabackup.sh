#/bin/bash
###########################
# Author : DJERBI Florian
# Object : Run full backup and incremental backup for all mariadb
# Creation Date : 01/04/2024
# Modification Date : 03/02/2024
###########################

#
# VARIABLES
#
source variable

#
# FUNCTIONS
#
function backup_full(){
    last_full_number=$1
    last_full_number=$((${last_full_number}+1))
    mariabackup --backup --stream=mbstream --user=root --extra-lsndir=${folder_backup}/${backup_full_name}-${last_full_number} | gzip > ${folder_backup}/${backup_full_name}-${last_full_number}.gz
}

function backup_inc(){
    last_full_number=$1
    last_inc_name=$(find ${folder_backup} -type f -name ${backup_inc_name}-${last_full_number}*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    last_inc_number=$(echo "${last_inc_name}" | cut -f4 -d/ |cut -f3 -d- |cut -f1 -d.)
    new_inc_number=$((${last_inc_number}+1))
    if [[ -z ${last_inc_name} ]];then
        echo "Run inc backup by last full !" >> log_file
        mariabackup --backup --stream=mbstream --incremental-basedir=${folder_backup}/${backup_full_name}-${last_full_number} --user=root --extra-lsndir=${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number} | gzip > ${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number}.gz
    else
        echo "Run inc backup by last inc !" >> log_file
        mariabackup --backup --stream=mbstream --incremental-basedir=${folder_backup}/${backup_inc_name}-${last_full_number}-${last_inc_number} --user=root --extra-lsndir=${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number} | gzip > ${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number}.gz
    fi
}

function check_last_full(){
    last_full_name=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    if [[ -z ${last_full_name} ]];then
        echo "Run first full backup !" >> log_file
	last_full_number=0
        sleep 3
	backup_full "${last_full_number}"
    else
        last_full_number=$(echo "${last_full_name}" | cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
        last_full_date=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -mtime -${incremental_day}-1 -printf "%T@ %Tc %p\n" | wc -l) 	# Prod
        # last_full_date=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -mmin -420 -printf "%T@ %Tc %p\n" | wc -l)			# Dev
        if [ ${last_full_date} -eq 0 ];then
            echo "Run full backup !" >> log_file
            sleep 3
            backup_full "${last_full_number}"
        else
            echo "Run inc backup !" >> log_file
            sleep 3
            backup_inc "${last_full_number}"
        fi
    fi
}


function check_old_backup(){
    count_full_backup=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz| wc -l)
    if [ ${count_full_backup} -gt ${full_retention} ]; then
        old_full_number=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |head -n 1 |cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
	if [ -n ${folder_backup} ];then
	    rm -rf ${folder_backup}/${backup_full_name}-${old_full_number}*
	    rm -rf ${folder_backup}/${backup_inc_name}-${old_full_number}*
            echo "Delete full and incremental backup ${old_full_number}" >> log_file
	fi
    fi
}

check_last_full "$@"
check_old_backup "$@"
