# Salt States

- This directory is used to *store salt states* that are to be executed in the container. 
- This directory is mapped to the docker container in [run_salt_states.sh](https://gitlab.freudenberg-it.com/itmall/devops-salt-container/blob/workspace/installation-scripts/run_salt_states.sh) script. 
- All files placed in this directory are mapped `/srv/salt` directory of the container, wherein the *salt-minion service* in the container would be using them to execute as per the command line argument (which is a salt state file/folder name) while executing [run_salt_states.sh](https://gitlab.freudenberg-it.com/itmall/devops-salt-container/blob/workspace/installation-scripts/run_salt_states.sh#L35).