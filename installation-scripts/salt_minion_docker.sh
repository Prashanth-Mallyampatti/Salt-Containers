#!/bin/bash

# Set variables
PROXY=http:\/\/10.133.132.165:8181
SALT_PATH=/root/devops-salt-container/salt-minion/

# Add ENV variables
echo
echo Setting proxies...
sed -i '/ENV HTTP/d' $SALT_PATH/Dockerfile
sed -i '/FROM .*/a ENV HTTP_PROXY "'$PROXY'"\nENV HTTPS_PROXY "'$PROXY'"' $SALT_PATH/Dockerfile

# Restart Docker
systemctl daemon-reload
systemctl restart docker

# Set Proxy Variable
export https_proxy=$PROXY
export http_proxy=$PROXY


# Build Docker image
echo
echo Building Docker image...
cd $SALT_PATH
docker build -t salt-minion .

# Run the Docker image\
echo
echo
echo Test Pinging minion...
echo
docker run -i salt-minion salt-call --local test.ping
