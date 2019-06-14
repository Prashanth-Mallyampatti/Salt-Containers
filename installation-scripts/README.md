# File Description and Comments

**Place and run all the scripts in `/root`.**
1. **`install_docker.sh`**: 
    - Installs latest version of *Docker CE* from repository for *Ubuntu* as the underlying system.
    - The script runs `apt update` and `apt upgrade`, so any concerns with updating other packages which are already installed on the system have to be manually taken care of.
    - If this error occurs (which will not be caught by `set -e`): *'Release file not yet valid'*, please use `timedatectl` to sync your system time with *NTP*.
    
2. **`configure_docker.sh`**:
    - Configures the Docker environment required to build and run *SaltStack* images. 
    - Sets *proxy* and *DNS* addresses at various places. Please change it them at the variable declaration section of the script. If *DNS* address added/removed then, also add `--dns <address>` in the first *sed* command of the script (line 38)
    - *Proxy* address used: `http://10.133.132.165:8181`
    - *DNS* addresses used: `10.130.128.1`, `10.130.22.95`, and `153.95.212.100`. These were obtained from *windows cmd line*: `ipconfig /all`.
    - This script creates *docker.service.d* for proxy setup. `http_proxy.conf` is created and used to that. If any issues: https://docs.docker.com/network/proxy/ <br /> https://docs.docker.com/config/daemon/systemd/ 
    - `systemctl daemon-reload` should always be accompanied (before) with `systemctl restart docker` for any changes in the docker config files and `Dockerfile`.
    
3. **`salt_minion_docker.sh`**:
    - Builds a *masterless salt-minion* container with default parameters with image name as `salt-minion`.
    - Uses `Dockerfile` from `salt-minion` folder of this repository, so directory structure should be preserved as it is.
    - Proxy *ENV* variables are set into the *Dockerfile*. 
    - *Test pings* the latest *salt-minion* image build in the foreground.

4. **`run_salt-states.sh`**:
    - *Runs* and *Execs* salt states the latest *salt-minion* image.
    - Container is mapped with a *local volume* (outside container): `/root/devops-salt-container/salt-states`. Salt states are placed in this local volume and are executed inside container.
    - Runs the container in background and executes the salt-states on the same by taking a command line argument (Check master README.md).