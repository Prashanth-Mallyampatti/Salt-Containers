# devops-salt-container

This repository contains all the necessary scripts to build openSUSE container to run salt-minion. 

Folder Description:
1. `installation-scripts`: Sripts to install docker, configure docker environment, build salt-minions in the docker container and run sample states.
2. `salt-minion`: Contains Dockerfile for building and running salt-minion (and also sample.sls for testing)
3. `salt-states`: Contains salt states which is used by the container

Note: 
- Run all the scripts in root mode only.
- The scripts are directory structure dependent.
- The proxy address used: `http://10.133.132.165:8181`
- DNS addresses used in the above scripts are obtained from windows cmd: `ipconfig /all`. So please update DNS variables in `configure_docker.sh` as per your addresses.
- Currently I have used three DNS addresses. If new DNS addresses added or removed then also add/remove `--dns $DNS'n'` in line 39 of `configure_docker.sh`
- Place all the salt's `.sls` files that are to be executed in `devops-salt-container/salt-states/` as `/root/devops-salt-container/salt-states` directory is being mapped as an external volume to the docker container. 
- Here the name of docker image used is: `salt-minion`
- If the salt state is defined in defined `top.sls` pass an empty argument(not even a space)in Step 6.


<br />Steps to set to build openSUSE container to run salt-minion with a sample state:

1. Clone this repository and place it in `/root` directory
2. `cd devops-salt-container/installation-scripts/`
3. Install Docker on Ubuntu 18.04 (virtual box behind a proxy server):
    <br />`yes Y | source ./install_docker.sh`
4. Configure Docker and set the environment:
    <br />`source ./configure_docker.sh`
5. Install salt-minion on a docker container and test ping:
    <br />`source ./salt_minion_docker.sh`
6. Run `.sls` state file on the the openSUSE docker container:
    <br />`bash ./run_salt_states.sh sample`
    <br />The above command takes one command line argument: name of the state file(which is placed in `salt-states` folder). In the above command `sample` is specified as the command line argument.


<br />Some useful links:

https://www.tecmint.com/zypper-commands-to-manage-suse-linux-package-management/
<br />https://docs.saltstack.com/en/latest/topics/tutorials/docker_sls.html
<br />https://qxf2.com/blog/how-to-get-the-code-inside-docker-container/
<br />https://docs.docker.com/install/linux/docker-ce/ubuntu/
<br />http://blog.baudson.de/blog/stop-and-remove-all-docker-containers-and-images
