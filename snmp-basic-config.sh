#!/bin/bash
#################################################################
###### This piece of code is released under GPL V3 License ######
#################################################################

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
		sleep 0.2s
	done
	if [ "$is_ok" -eq "1" ];then
		echo -n " [ ${green}${msg}${reset} ]\n"
	else
		echo -n " [ ${red}${msg}${reset} ]\n"
	fi
}

# TODO: Logging events

clear
echo "#################################################################"
echo "######## This piece of code is GPL V3 and is free to use ########"
echo "#################################################################"
echo "\n"
read -p "Your SNMP Server IP Address: " IP
read -p "Your specified community name: " COMMUNITY

#IP="172.20.90.1"	# sample data
#COMMUNITY="IDC" 	# sample data

echo -n "\nChecking for SNMP agent configuration "
# TODO: next version fixture
#ps aux|grep -v grep|grep snmpd
#/etc/snmpd/snmpd.conf
#/etc/init.d/snmpd
if ! [ -f /etc/initd/snmpd ];then
	progress 0 "SNMP agent is not installed"
	read -p "Do you want to install snmpd package: (Y/n) " prompt
	echo $prompt
	if [ \( "$prompt" = "Y" \) -o \( "$prompt" = "y" \) ];then
		sudo apt-get update
		sudo apt-get install snmpd
		echo "Snmpd installed successfully :)"
	else
		if [ "$prompt" = "n" ];then
			echo "\n Script will now terminate "
			progress 1 "Good luck!"
			exit 0
		fi
	fi
else
	progress 1 "SNMP is already installed"
fi
sudo mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.org
sudo echo "rocommunity $COMMUNITY" > /etc/snmp/snmpd.conf
echo -n "Configuring /etc/snmpd/snmpd.conf "
progress 1 "Done!"

if [ -f /etc/default/snmpd ];then
	sudo replace "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -p /var/run/snmpd.pid'" "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" -- /etc/default/snmpd
else
	sudo echo "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" > /etc/default/snmpd
fi
echo -n "Configuring /etc/default/snmpd "
progress 1 "Done!"
sudo iptables -A INPUT -p udp -s $IP --dport 161 -j ACCEPT
echo -n "Configuring ip tables "
progress 1 "Done!"
sudo /etc/init.d/snmpd restart
echo -n "Starting snmpd agent service "
progress 1 "Done!"
