#!/bin/bash

# Docker commands to run salt states placed outside the containers

echo 
echo Running Docker Container for the image: salt-minion
CONTAINER=`docker run -d -it -v /root/salt-states:/srv/salt salt-minion`

echo
echo Container ID:$CONTAINER
echo
echo Running salt states...
echo
docker exec -i $CONTAINER salt-call --local state.apply sample
