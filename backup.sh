#!/bin/bash

# TODO: adding hostname to backupfile
# TODO: gathering some info from args 1.where to save backup 2. which directories
# TODO: changing scp to rsync
# TODO: changing log method
# TODO: readd about log levels
# gathering some info from env

# TODO: get rid of these
NOW=$(date +"%Y-%m-%d")
ADDRESS=$2
DEST = $1

# to backup git repositories
git(){
	git_address=$1
	# TODO: merge this sction to script -- gits

	NOW=$(date +"%Y-%m-%d")
	LOGFILE="/home/backup/git_172.20.5.240/backup.log"

	echo "---------------------- $NOW git backup starts  ---------------------" >> $LOGFILE 2>&1
	for dir in `ssh gitdev@172.20.5.240 | awk '{print $2}' | tr '\n' ' '`
	do
		if [ $dir = "support@xamin.ir," -o $dir = "W" ]:
		then
			continue
		else
			path="/home/backup/git_172.20.5.240/$dir"
			if [ -d "${path}" ]:
			then
				cd $path
				echo "$(date) :: dir=$dir path=$path" >> $LOGFILE 2>&1
				echo -n "$(date) :: $dir :: " >> $LOGFILE 2>&1
				git pull >> $LOGFILE 2>&1
			else
				cd /home/backup/git_172.20.5.240/
							echo "$(date) :: dir=$dir path=$path" >> $LOGFILE 2>&1
				echo -n "$(date) :: $dir :: " >> $LOGFILE 2>&1
				git clone gitdev@172.20.5.240:$dir $path  >> $LOGFILE 2>&1
			fi

		fi
	done
	echo "-------------------------------------------------------------------" >> $LOGFILE 2>&1
};
# Test Case: git_backup <git address url>
#######################################################################

files_backup(){
	# Method can be incrimental or fixed size
	method=$1
	# Source should be comma or space seperated file or directory name
	source=$2
	# Destination should be a directory name

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

};
# Test Case: files_backup <method> <source(s)> <destination>
#######################################################################

mysql_backup(){
	# TODO: merge this section to script -- mysql dbs

	NOW=$(date +"%Y-%m-%d")
	ADDRESS="172.20.5.212"
	FILE="mysql_${ADDRESS}_${NOW}.tar.bz2"

	echo "---------------- $NOW ---------------" >> /root/backup.log

	echo "Backing up data to $FILE file" >> /root/backup.log
	mysqldump -u root -pxaminmysql92 portal > portal_$NOW.sql
	mysqldump -u root -pxaminmysql92 wiki > wiki_$NOW.sql
	mysqldump -u root -pxaminmysql92 ask > ask_$NOW.sql

	tar cvjf /tmp/$FILE portal_$NOW.sql ask_$NOW.sql wiki_$NOW.sql

	echo "Moving to $FILE file to 172.20.5.211/home/backup" >> /root/backup.log
	scp -i .ssh/id_rsa /tmp/$FILE saver@172.20.5.211:/home/backup/

	echo "Removing /root/$FILE temporary file" >> /root/backup.log
	rm /tmp/$FILE portal_$NOW.sql ask_$NOW.sql wiki_$NOW.sql
};
# Test case: mysql_backup
######################################################################