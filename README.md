# Backup MySQL
- Author : DJERBI Florian
- Object : Backup mysql full and incremental
- Creation Date : 02/28/2024
- Modification Date : 03/02/2024

## Variables
```
incremantal_day=7                           # day before full backup
full_retention=3                            # retention day for full backup
folder_backup=""                            # folder for backups
log_file="${folder_backup}/backup.log"      # log file
backup_full_name="backup_full"              # name file/folder full backup
backup_inc_name="backup_inc"                # name file/folder inc backup
db_host="localhost"
db_port=3306
db_user=""                                  # set your user password
db_password=""                              # set your password db
```
