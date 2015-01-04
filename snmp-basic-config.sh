#!/bin/sh

###############################
###### this is a GPL  V3 ######
###############################


echo "\nyou need to enter the IP address and community name as args\n"
echo "example sudo ssh snmp-basic-config.sh 192.168.1.2 community-name"


if ! [ -f /etc/snmp/snmpd.conf ];then
	apt-get install snmpd
fi
mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.org
echo "rocommunity $2" > /etc/snmp/snmpd.conf

if [-f /etc/default/snmpd];then
	replace "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -p /var/run/snmpd.pid'" "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" -- /etc/default/snmpd
else
	echo "SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -c /etc/snmp/snmpd.conf'" > /etc/default/snmpd
fi
iptables -A INPUT -p udp -s $1 --dport 161 -j ACCEPT
/etc/init.d/snmpd restart

