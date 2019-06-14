#!/bin/bash
#
# Description: checks the status of HDDs of physical Cisco systems
#

# Checking if user as the rights
tmp=`sudo dmidecode -t system`
tmp2=`sudo ipmitool sdr`
if [[ -z "$tmp" ]] || [[ -z "$tmp2" ]]
then
	echo "UNKNOWN - Variables are empty. Check sudo rights of user nagios."
    exit 3
fi

# Checking if Cisco System
if [ `sudo dmidecode -t system | grep -i cisco | wc -l` -eq 0 ]
then
	echo "UNKNOWN - no Cisco System according to oslevel"
	exit 3
fi

# Checking if needed modul is running
if [ `ls -l /dev/ | grep ipm | wc -l` -ne 0 ]
then
	number=`ipmitool sdr type "Drive Slot / Bay" | grep -Ev 'ok|ns' | wc -l`
	if [ $number -eq 0 ]
	then
		echo "OK - all HDDs are ok."
		exit 0
	elif [ $number -eq 1 ]
	then
		echo "WARNING - 1 HDD is defect."
		exit 1
	else
		echo "CRITICAL - $number HDDs are defect."
		exit 2
	fi
else	
	echo "UNKNOWN - Modules for ipmitool are not loaded. Execute: 'modprobe ipmi_devintf ; modprobe ipmi_si ;'"
	exit 3
fi
