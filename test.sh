#!/bin/bash

progress(){
	# color code constants
	red=`tput setaf 1`
	green=`tput setaf 2`
	reset=`tput sgr0`
	# variables
	progress=10
	is_ok=$1
	msg=$2
	for i in `seq 1 $progress`
	do
		echo -n "."
		sleep 0.3s
	done
	if [ "$is_ok" -eq "1" ];
	then
		echo -n " [ ${green}${msg}${reset} ]\n"
	else
		echo -n " [ ${red}${msg}${reset} ]\n"
	fi
}


echo -n "Checking SNMP agent existance "
progress "1" "Done!"

echo -n "Checking SNMP agent existance "
progress 0 "error!"