#!/bin/bash

# Set variables
PROXY=http:\/\/10.133.132.165:8181

# Clone into OpenSUSE docker container 
rm -rf docker-containers

git clone https://github.com/openSUSE/docker-containers.git

cp -r docker-containers/derived_images/salt/salt-minion .


# Add ENV variables
sed -i '/FROM .*/a ENV HTTP_PROXY "'$PROXY'"\nENV HTTPS_PROXY "'$PROXY'"\n' salt-minion/Dockerfile

# Restart Docker
systemctl daemon-reload
systemctl restart docker

# Set Proxy Variable
export https_proxy=$PROXY
export http_proxy=$PROXY


# Build Docker image
echo
echo Building Docker image...
cd /root/salt-minion/
docker build -t salt-minion .

# Run the Docker image\
echo
echo
echo Pinging minion...
echo
# docker run -i salt-minion salt-call --local test.ping


# Run a sample sls
cp -r /root/sample.sls .
docker run -i salt-minion salt-call --local 
