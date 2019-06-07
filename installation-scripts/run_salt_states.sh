#!/bin/bash

# Docker commands to run salt states placed outside the containers

echo 
echo Running Docker Container for the image: salt-minion
CONTAINER=`docker run -d -i -t -v /root/devops-salt-container/salt-states:/srv/salt salt-minion`

echo
echo Container ID:$CONTAINER
echo
echo Running salt states...
echo
# Takes command line argument for the .sls state name
docker exec -i $CONTAINER salt-call --local state.apply $1
