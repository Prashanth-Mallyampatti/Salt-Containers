#!/bin/bash

set -e

# Run the script in root mode

# Set variables
# SALT_PATH here is directory structure dependent and should be retained in the same order for successful build
PROXY="http://10.133.132.165:8181"
SALT_PATH="/root/devops-salt-container/salt-minion/"


# Add ENV variables
echo
echo Setting proxies...
sed -i '/ENV HTTP/d' $SALT_PATH/Dockerfile
sed -i '/FROM .*/a ENV HTTP_PROXY "'$PROXY'"\nENV HTTPS_PROXY "'$PROXY'"' $SALT_PATH/Dockerfile


# Restart Docker
# Restarting docker isn't sufficient, it should be accompanied by daemon reload
systemctl daemon-reload
systemctl restart docker


# Set Proxy Variable
# 'source' execution required
export https_proxy=$PROXY
export http_proxy=$PROXY


# Build Docker image
# Tag field is left blank, so docker picks :latest as default
echo
echo Building Docker image...
docker build -t salt-minion $SALT_PATH


# Check for build success
docker image inspect salt-minion:latest > /dev/null
if [ $? -eq 0 ]
then
    echo
    echo "Build Successful."
    echo
else
    echo
    echo "Build Unsuccesful."
    echo
fi

# Run the Docker image
# If some TTY issue raised(like when piping commands), please remove -t option in the below command
echo
echo Test Pinging minion...
echo
docker run -i -t salt-minion salt-call --local test.ping
