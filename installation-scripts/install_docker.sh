#!/bin/bash

#Run the following script in root mode

# Set Proxy Variable
# To set environment variables through script use 'source' to build that script
export https_proxy="http://10.133.132.165:8181"
export http_proxy="http://10.133.132.165:8181"


# Kill processes holding locks except with PIDs.
# Remove any locks held by those processes
# And reconfigure the packages if necessary
declare -a locks=("/var/lib/dpkg/lock*" "/var/lib/apt/lists/lock" "/var/cache/apt/archives/lock")
for val in ${locks[@]}; do
  PID=$(lsof -t $val 2>&1)
  if [ $? -eq 0 ] && [ ! -z "$PID" ]
  then
    kill -9 $PID
  fi
  rm -rf $val 
done


# After removing locks, reconfiguring the packages
echo Package Reconfiguration...
dpkg --configure -a

# Remove older versions of docker
apt-get remove docker docker-engine docker.io containerd runc

# Catch errors from here
set -e

# Install Docker from repository
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

# Verify docker is installed
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
