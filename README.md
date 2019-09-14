# devops-salt-container

**This repository contains all the necessary scripts to build openSUSE container to run salt-minion.** 

<br />

**Folder Description:**
1. **`installation-scripts`**: Sripts to install docker, configure docker environment, build salt-minions in the docker container and run salt states.
2. **`salt-minion`**: Contains Dockerfile for various linux dsitributions for building and running containers.
3. **`salt-states`**: Contains salt states which is used by the container

<br />

**Note:** 
- Place and run all scripts in `/root` only.
- The scripts are *directory structure dependent*.
- Place all the salt's `.sls` files/folders that are to be executed in `devops-salt-container/salt-states/`
- The repo was devoped and tested on Vagrant Ubuntu 18.04 machine.
- Enter proxy address along with port number in the format :
``` shell 
http://<proxy_address>:<port_number>
```


<br />**Steps to set to build openSUSE container to run salt-minion with a sample state:**

1. Clone this repository and place it in `/root` directory
2. **`cd devops-salt-container/installation-scripts/`**
3. Start the script
    <br />**`source ./init.sh`**
    <br />The scripts installs Docker, configures the docker enviroment, builds Docker images for the following distributions: `Ubuntu 18.04`, `Opensuse 12`, and `Centos 7`, runs the container. After successful run, the developer would have fully configured docker container with salt-minion and essential dependencies installed running and will be logged into the container. 

<br />**Some useful links:**

https://docs.saltstack.com/en/latest/topics/tutorials/docker_sls.html
<br />https://docs.docker.com/install/linux/docker-ce/ubuntu/
<br />http://blog.baudson.de/blog/stop-and-remove-all-docker-containers-and-images
