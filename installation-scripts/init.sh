#!/bin/bash

set -e

echo
echo Creating unit test environment
echo
echo Images available:
echo 1.SUSE 42.3
echo 2.Ubuntu 18.04
echo 3.Centos 7
echo
echo Select any one from the above list:
read option
echo
echo "Are you behind a proxy server ? [y/n]"
read yes_no

call_scripts()
{
	source ./install_docker.sh
	
	source ./configure_docker.sh
	
	source ./salt_minion_docker.sh
}

case "$yes_no" in

	[Yy])
	PROXY_FLAG=1
	echo
	echo "Enter proxy address(include protocol type if applicable):"
	read proxy_address
	echo
	echo Enter proxy port:
	read proxy_port
	config_file="proxy_ip_port.conf"
	if [ -f $config_file ] ; then
		rm $config_file
	fi
	touch $config_file
	echo -e "proxy_ip:$proxy_address\\nproxy_port:$proxy_port" > $config_file
	
	call_scripts
	
	;;

        [Nn])
	
	PROXY_FLAG=0
	call_scripts
	
	;;
	
	*) 
	echo Invalid input
	exit 1
	;;
esac

