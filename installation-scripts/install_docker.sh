#!/bin/bash

#Run the following script in root mode

# Look for processes holding locks.
# If no process is holding the lock then remove the lock.
declare -a locks=("/var/lib/dpkg/lock*" "/var/lib/apt/lists/lock" "/var/cache/apt/archives/lock")
FLAG=0
for val in ${locks[@]}; do
  PID=$(lsof -t $val 2>&1)
  LSOF_EXIT_CODE=$?
  WAIT_TIME=2

  while [ $LSOF_EXIT_CODE -eq 0 ] && [[ $PID =~ ^[0-9]+$ ]] && [ $WAIT_TIME -gt 0 ]
  do
    echo
    echo Lock: $val held by process $PID
    echo Waiting $[WAIT_TIME*10] seconds for process $PID to exit..
    sleep 10
    WAIT_TIME=$[WAIT_TIME-1]
    PID=$(lsof -t $val 2>&1)
    LSOF_EXIT_CODE=$?
  done

  if [ $WAIT_TIME -le 0 ] || [[ $PID =~ ^[0-9]+$ ]]
  then
    echo
    echo Process $PID is still running with lock $val held.
    echo Terminating Docker CE installation. 
    echo Exiting with code=1
    exit 1
  fi

  ls -l $val > /dev/null 2>&1
  if [ $? -eq 0  ]
  then
    echo No process is holding $val. Releasing it..
    rm -rf $val
    FLAG=1
  fi

done

# If any locks removed reconfigure the packages
if [ $FLAG -eq 1 ]
then
  echo
  echo Package Reconfiguration...
  dpkg --configure -a
fi

# Remove older versions of docker
apt-get remove docker docker-engine docker.io containerd runc


# Catch errors from here
set -e

# Set Proxy Variables
# To set environment variables through script use 'source' to build
IP=$(awk -F'proxy_ip:' '{print $2}' .gitignore)
PORT=$(awk -F'proxy_port:' '{getline;print $2}' .gitignore)
PROXY="$IP:$PORT"
export https_proxy=$PROXY
export http_proxy=$PROXY


# Install Docker CE from repository
apt update
apt upgrade

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt update
apt upgrade

apt-get install docker-ce docker-ce-cli containerd.io


# Verify docker installation
docker --version
if [ $? -eq 0 ]
then
    echo
    echo "Docker Installation Successful"
    echo
else
    echo
    echo "Docker Installation Failed"
    echo
fi
