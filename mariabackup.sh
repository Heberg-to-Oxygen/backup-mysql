#/bin/bash
###########################
# Author : DJERBI Florian
# Object : Run full backup and incremantal backup for all mariadb
# Creation Date : 01/04/2024
# Modification Date : 01/05/2024
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
        echo "Run inc backup by last full !"
        mariabackup --backup --stream=mbstream --incremental-basedir=${folder_backup}/${backup_full_name}-${last_full_number} --user=root --extra-lsndir=${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number} | gzip > ${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number}.gz
    else
        echo "Run inc backup by last inc !"
        mariabackup --backup --stream=mbstream --incremental-basedir=${folder_backup}/${backup_inc_name}-${last_full_number}-${last_inc_number} --user=root --extra-lsndir=${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number} | gzip > ${folder_backup}/${backup_inc_name}-${last_full_number}-${new_inc_number}.gz
    fi
}

function check_last_full(){
    last_full_name=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    if [[ -z ${last_full_name} ]];then
        echo "Run first full backup !"
	last_full_number=0
        sleep 3
	backup_full "${last_full_number}"
    else
        last_full_number=$(echo "${last_full_name}" | cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
        # last_full_date=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -mtime -${incremantal_day} -printf "%T@ %Tc %p\n" | wc -l) 	# Prod
        last_full_date=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -mmin -420 -printf "%T@ %Tc %p\n" | wc -l)			# Dev
        if [ ${last_full_date} -eq 0 ];then
            echo "Run full backup !"
            sleep 3
            backup_full "${last_full_number}"
        else
            echo "Run inc backup !"
            sleep 3
            backup_inc "${last_full_number}"
        fi
    fi
}

check_last_full "$@"

