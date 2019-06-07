# devops-salt-container

This repository contains all the necessary scripts to build openSUSE container to run salt-minion. 

Folder Description:
1. `installation-scripts`: Scripts to install docker, configure docker environment, build salt-minions in the docker container and run sample states.
2. `salt-minion`: Contains Dockerfile for building and running salt-minion (and also sample.sls for testing)
3. `salt-states`: Contains salt states which is used by the container

Note: 
- Run all the scripts in root mode only.
- The scripts are directory structure dependent.
- DNS addresses used in the above scripts are obtained from windows cmd: `ipconfig /all`
- Place all the salt's `.sls` files that are to be executed in `devops-salt-container/salt-states/`
- Here the name of docker image used is: `salt-minion`
- If the salt state is defined in defined `top.sls` pass empty argument in Step 6.


Steps to set to build openSUSE container to run salt-minion with a sample state:

1. Clone this repository and place it in root directory.
2. `cd devops-salt-container/installation-scripts/`
3. Install Docker on Ubuntu 18.04 (virtual box behind a proxy server):
    <br />`yes Y | bash ./install_docker.sh`
4. Configure Docker and set the environment:
    <br />`yes Y | bash ./configure_docker.sh`
5. Install salt-minion on a docker container and test ping:
    <br />`yes Y | bash ./salt_minion_docker.sh`
6. Run `.sls` state file on the the openSUSE docker container:
    <br />`yes Y | bash ./run_salt_states.sh sample`
    <br />The above command takes one command line argument: name of the state file(which is placed in `salt-states` folder)