#/bin/bash
###########################
# Author : DJERBI Florian
# Object : Run full backup and incremantal backup for all mariadb
# Creation Date : 01/04/2024
# Modification Date : 01/04/2024
###########################

#
# VARIABLES
#
incremantal_day=7
folder_backup="/tmp/mariadb-backup"
full_backup_count=1
inc_backup_count=1
backup_full_name="backup_full"
backup_inc_name="backup_inc"

#
# TEMPLATES FUNCTIONS
#
function backup_full(){
    last_full_name=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    last_full_number=$(echo "${last_full_name}" | cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
    echo "Last full backup number is ${last_full_number}"
    full_backup_count=$((${full_backup_count}+1))
    echo "${full_backup_count}"
    mariabackup --backup --stream=mbstream --user=root --extra-lsndir=${folder_backup}/${backup_full_name}-${full_backup_count} | gzip > ${folder_backup}/${backup_full_name}-${full_backup_count}.gz
}

function backup_inc(){
    last_full_name=$(find ${folder_backup} -type f -name ${backup_full_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    last_full_number=$(echo "${last_full_name}" | cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
    last_inc_name=$(find ${folder_backup} -type f -name ${backup_inc_name}-*.gz -printf "%T@ %Tc %p\n" |sort -n |tail -n 1)
    last_inc_number=$(echo "${last_inc_name}" | cut -f4 -d/ |cut -f2 -d- |cut -f1 -d.)
    echo "Last incremental backup number is ${last_inc_number}"
    inc_backup_count=$((${last_inc_number}+1))
    echo "${inc_backup_count}"
    mariabackup --backup --stream=mbstream --incremental-basedir=${folder_backup}/${backup_full_name}-${last_full_number} --user=root --extra-lsndir=${folder_backup}/${backup_inc_name}-${inc_backup_count} | gzip > ${folder_backup}/${backup_inc_name}-${inc_backup_count}.gz
}

# function main(){
#     backup_full "$@"
#     backup_inc "$@"
# }

# main "$@"

$1 "$@" $2 "$@"
