#!/bin/bash

set -e

# Run the script in root mode

# Set variables
# SALT_PATH here is directory structure dependent and should be retained in the same order for successful build

IP=$(sed -e 's|\/|\\\/|g' <<< "$(awk -F'proxy_ip:' '{print $2}' .gitignore)")
SALT_IP=$(sed -e 's|\\|\\\\|g' <<< $IP)
PORT=$(awk -F'proxy_port:' '{getline;print $2}' .gitignore)
PROXY="$IP:$PORT"

SALT_PATH="/root/devops-salt-container/salt-minion/"
SALT_PROXY_IP="sed -i 's/#proxy_host:.*/proxy_host: $SALT_IP/g' /etc/salt/minion"
SALT_PROXY_PORT="sed -i 's/#proxy_port:.*/proxy_port: $PORT/g' /etc/salt/minion"
MINION_FILE="touch \/etc\/salt\/minion"

# Add ENV variables
echo
echo Setting proxies...
sed -i '/ENV HTTP/d' $SALT_PATH/Dockerfile
sed -i '/FROM .*/a ENV HTTP_PROXY "'$PROXY'"\nENV HTTPS_PROXY "'$PROXY'"' $SALT_PATH/Dockerfile


# Add proxies for salt-minion inside container
echo
echo Adding salt-minion proxies...
sed -i -e '/proxy_host: .*/d' \
       -e '/proxy_port: .*/d' \
       $SALT_PATH/Dockerfile
sed -i "s|$MINION_FILE.*|$MINION_FILE \&\& \\\\\n    $SALT_PROXY_IP \&\& \\\\\n    $SALT_PROXY_PORT|g" $SALT_PATH/Dockerfile


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
echo Building OpenSuse Docker image 42.3
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
