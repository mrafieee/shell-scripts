#!/bin/bash

###########################################################
###### This piece of code is released under a GPL V3 ######
###########################################################


echo "\nyou need to enter the IP address and community name as args\n"
echo "example sudo sh snmp-basic-config.sh 192.168.1.2 community-name"


if ! [ ps aux |grep -v grep|grep snmpd ];then
	echo -n "snmpd is running well \nconfiguring snmp ."
	for ((i=0;i<5;i++));do
		sleep 500 ms
		echo -n "."
	done
	echo -n "\n"

	apt-get install snmpd
fi
mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.org
echo "rocommunity $2" > /etc/snmp/snmpd.conf

if [ -f /etc/default/snmpd ];then
	replace "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -p /var/run/snmpd.pid'" "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" -- /etc/default/snmpd
else
	echo "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" > /etc/default/snmpd
fi
iptables -A INPUT -p udp -s $1 --dport 161 -j ACCEPT
/etc/init.d/snmpd restart

