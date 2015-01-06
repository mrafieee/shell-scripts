#!/bin/bash

# TODO: adding hostname to backupfile
# TODO: gathering some info from args 1.where to save backup 2. which directories
# TODO: changing scp to rsync
# TODO: changing log method
# gathering some info from env

NOW=$(date +"%Y-%m-%d")
ADDRESS=$2
DEST = $1
# TODO: adding hostname to backupfile
FILE="_${ADDRESS}_${NOW}.tar.bz2"

echo "---------------- $NOW ---------------" >> /root/backup.log

echo "Backing up data to $FILE file" >> /root/backup.log
logger "Backing up data to $FILE file"
tar cvjf /tmp/$FILE /var/www/ /etc/

echo "Moving to $FILE file to $1" >> /root/backup.log
logger "Backing up data to $FILE file"
scp -i .ssh/id_rsa /root/$FILE saver@$1:/home/backup/

echo "Removing /root/$FILE temporary file" >> /root/backup.log
logger "Backing up data to $FILE file"
rm /tmp/$FILE

