#!/bin/bash
#
# Description: checks the status of Hardware of physical Cisco systems
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
	number=`sudo ipmitool sdr | grep -Ev 'ok|ns|nr|cr' | wc -l`
	if [ $number -eq 0 ]
	then
		echo "OK - hardware status is ok."
		exit 0
	else
		output=`sudo ipmitool sdr | grep -Ev 'ok|ns|nr|cr'`
		printf "CRITICAL - Please check: \n$output."
		exit 2
	fi
else	
	echo "UNKNOWN - Modules for ipmitool are not loaded. Execute: 'modprobe ipmi_devintf ; modprobe ipmi_si ;'"
	exit 3
fi
