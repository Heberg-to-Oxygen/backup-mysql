# Backup MySQL
- Author : DJERBI Florian
- Object : Backup mysql full and incremental
- Creation Date : 02/28/2024
- Modification Date : 03/10/2024

## Variables
```
incremental_day=7               # day before full backup
full_retention=3                # retention day for full backup
folder_backup=""                # folder for backups
backup_full_name="backup_full"  # name file/folder full backup
backup_inc_name="backup_inc"    # name file/folder inc backup

# Db information for backup
db_host="localhost"
db_port=3306
db_user=""                      # set your user password
db_password=""                  # set your password db

# S3 config
s3_backup=no				    # yes or no
s3_retention_day=90			    # retention of days in S3
s3_name="h2o-backup-mysql"		# s3 name on aws or other cloud
s3_path="lab1.ta-info.net"		# if our use sub folder
```

## Requirement
Install a [Mariadb](https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-11) instance

Packages requirement
``` bash
sudo apt update
sudo apt upgrade
sudo apt install gzip vim git mariadb-backup
```

Install awscli in linux if you use this option
``` bash
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install
sudo apt install awscli
```

## Install
Tip: create a linux user

Clone a repository
``` bash
su - $USER
cd /
git clone https://github.com/Heberg-to-Oxygen/backup-mysql.git
chmod u+x backup_alldb.sh
```

Edit and config variable
``` bash
cp variable.template variable
vim variable
```

### Option S3
If you want a copy in an S3, you must create it, know the credentials and configure the variable file
``` bash
vim variable
```

## Use
Manual test
``` bash
su - $USER
cd mariabackup/
/bin/bash backup_alldb.sh
```

Create a crontab to launch the script automatically
``` bash
crontab -e
15 00 * * * cd /$PATH/mariabackup && /bin/bash backup_alldb.sh
```

