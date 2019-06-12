#!/bin/bash

set -e

# Run this script in root mode
# Docker commands to run salt states placed outside the containers

# Run Docker
echo 
echo Running Docker Container for the image: salt-minion
CONTAINER=$(docker run --privileged -d -i -t \
            -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
            -v /root/devops-salt-container/salt-states:/srv/salt:ro \
            salt-minion)


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


# Execute salt states
# Takes salt state file/folder name as a command line argument
echo
echo Executing \'$1\' salt state as a minion...
echo
docker exec -i -t $CONTAINER salt-call --local state.apply $1
