# devops-salt-container

**This repository contains all the necessary scripts to build openSUSE container to run salt-minion.** 

<br />

**Folder Description:**
1. **`installation-scripts`**: Sripts to install docker, configure docker environment, build salt-minions in the docker container and run salt states.
2. **`salt-minion`**: Contains Dockerfile for building and running salt-minion.
3. **`salt-states`**: Contains salt states which is used by the container

<br />

**Note:** 
- Place and run all scripts in `/root` only.
- The scripts are *directory structure dependent*.
- The *proxy* address used: `http://10.133.132.165:8181`. Please update it in `../installation-scripts/.gitgnore` file.
- Place all the salt's `.sls` files/folders that are to be executed in `devops-salt-container/salt-states/` 
- If the salt state is defined in defined `top.sls` pass an empty argument (not even a space) in Step 6.


<br />**Steps to set to build openSUSE container to run salt-minion with a sample state:**

1. Clone this repository and place it in `/root` directory
2. **`cd devops-salt-container/installation-scripts/`**
3. Install Docker on Ubuntu (virtual box behind a proxy server):
    <br />**`yes Y | source ./install_docker.sh`**
4. Configure Docker and set the environment:
    <br />**`source ./configure_docker.sh`**
5. Install salt-minion on a docker container and test ping:
    <br />**`source ./salt_minion_docker.sh`**
6. Run state file/folder on the the openSUSE docker container:
    <br />**`bash ./run_salt_states.sh sample`**
    <br />The above command takes one command line argument: name of the state file(which is placed in `salt-states` folder). In the above command *sample* is specified as the command line argument.


<br />**Some useful links:**

https://www.tecmint.com/zypper-commands-to-manage-suse-linux-package-management/
<br />https://docs.saltstack.com/en/latest/topics/tutorials/docker_sls.html
<br />https://qxf2.com/blog/how-to-get-the-code-inside-docker-container/
<br />https://docs.docker.com/install/linux/docker-ce/ubuntu/
<br />http://blog.baudson.de/blog/stop-and-remove-all-docker-containers-and-images
