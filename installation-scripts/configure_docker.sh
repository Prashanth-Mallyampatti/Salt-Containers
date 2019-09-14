#!/bin/bash

set -e

#Run the following script in root mode

echo
echo
echo "############## Configuring Docker ###############"
echo

if [ $PROXY_FLAG -eq 1 ]
then
	#Set variables, the following DNS addresses are obtained from windows cmd line: ipconfig /all
	IP=$(awk -F'proxy_ip:' '{print $2}' $config_file)
	PORT=$(awk -F'proxy_port:' '{getline;print $2}' $config_file)
	PROXY="$IP:$PORT"

	DOCKER_PATH="/etc/default/docker"
	PROXY_PATH="/etc/systemd/system"

	# Set Proxy Variable
	export https_proxy=$PROXY
	export http_proxy=$PROXY


	#Docker Configuration
	echo
	echo Setting proxies in Docker https_proxy.conf ....
	rm -rf $PROXY_PATH/docker.*
	mkdir $PROXY_PATH/docker.service.d
	touch $PROXY_PATH/docker.service.d/http_proxy.conf


	#Add proxies to the above created file
	echo "[Service]">>$PROXY_PATH/docker.service.d/http_proxy.conf
	echo "Environment=\"HTTP_PROXY=$PROXY/\"">>$PROXY_PATH/docker.service.d/http_proxy.conf
	echo "Environment=\"HTTPS_PROXY=$PROXY/\"">>$PROXY_PATH/docker.service.d/http_proxy.conf


	#Update proxies
	sed -i '/export https_\|HTTP_\|HTTPS_/d' $DOCKER_PATH
	sed -i 's|.*export http_proxy.*|export http_proxy="'$PROXY'/"\nexport https_proxy="'$PROXY'/"\nexport HTTP_PROXY="'$PROXY'/"\nexport HTTPS_PROXY="'$PROXY'/"|g' $DOCKER_PATH
else
	echo
	echo No proxies set for Docker environment
fi

# Restart Docker
echo 
echo Restarting Docker...
systemctl daemon-reload
systemctl restart docker
