#!/bin/bash

set -e

# Run this script in root mode
# Docker commands to run salt states placed outside the containers

echo
echo
echo "############# Running container ###############"

# Run Docker
echo 
echo Running Docker Container for the image: "$IMAGE_NAME"-salt-minion
CONTAINER=$(docker run --privileged -d -i -t \
            -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
            -v /root/devops-salt-container/salt-states:/srv/salt:rw \
            "$IMAGE_NAME"-salt-minion)

# Docker run success test 
docker container inspect $CONTAINER > /dev/null
if [ $? -eq 0 ]
then
    echo
    echo Docker container running
    echo Container ID: $CONTAINER
else
    echo
    echo Docker run failed
fi

# Into the container
echo
echo Bash into the container..
echo
docker exec -i -t $CONTAINER bash

