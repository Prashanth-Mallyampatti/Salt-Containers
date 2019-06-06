#!/bin/bash

#Run the following script in root mdde

#Set variables
PROXY=http:\/\/10.133.132.165:8181
DNS1=10.130.128.1
DNS2=10.130.22.95
DNS3=153.95.212.100
DOCKER_PATH=/etc/default/docker
# Set Proxy Variable
export https_proxy=$PROXY
export http_proxy=$PROXY


#Docker Configuration
PROXY_PATH=/etc/systemd/system
rm -rf $PROXY_PATH/docker.*
mkdir $PROXY_PATH/docker.service.d
touch $PROXY_PATH/docker.service.d/http_proxy.conf


#Add proxies to the above created file
echo "[Service]">>$PROXY_PATH/docker.service.d/http_proxy.conf
echo "Environment=\"HTTP_PROXY=$PROXY/\"">>$PROXY_PATH/docker.service.d/http_proxy.conf
echo "Environment=\"HTTPS_PROXY=$PROXY/\"">>$PROXY_PATH/docker.service.d/http_proxy.conf

DOCKER_PATH=/etc/default/docker

# The following DNS addresses are obtained from Windows cmd line: ipconfig /all
# Update the following commands according to your DNSs
DNS1=10.130.128.1
DNS2=10.130.22.95
DNS3=153.95.212.100


# Modify docker config files so as to accomodate the above proxy settings
sed -i 's|.*DOCKER_OPTS=.*|DOCKER_OPTS="--dns '$DNS1' --dns '$DNS2' --dns '$DNS3'"|g' $DOCKER_PATH

#Update proxies
sed -i '/export https_\|HTTP_\|HTTPS_/d' $DOCKER_PATH

sed -i 's|.*export http_proxy.*|export http_proxy="'$PROXY'/"\nexport https_proxy="'$PROXY'/"\nexport HTTP_PROXY="'$PROXY'/"\nexport HTTPS_PROXY="'$PROXY'"|g' $DOCKER_PATH


# Restart Docker
systemctl daemon-reload
systemctl restart docker
