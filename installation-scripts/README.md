# File Description and Comments

**Place and run all the scripts in `/root`.**
1. **`install_docker.sh`**: 
    - Installs latest version of *Docker CE* from repository for *Ubuntu 18.04 Server* as the underlying system.
    - The script runs `apt update` and `apt upgrade`, so any concerns with updating other packages which are already installed on the system have to be manually taken care of.
    - If this error occurs (which will not be caught by `set -e`): *'Release file not yet valid'*, please use `timedatectl` to sync your system time with *NTP* and rebbot the system.
    
2. **`configure_docker.sh`**:
    - Configures the Docker environment required to build and run *SaltStack* images. 
    - Sets *proxy* addresses at various places obtianed from `.gitignore`.
    - *Proxy* address used: `http://10.133.132.165:8181`
    - If any *DNS* address issue faced, set your *DNS* addresses in `/etc/default/docker` file at line: `DOCKER_OPTS="..."`
    - This script creates *docker.service.d* for proxy setup. `http_proxy.conf` is created and used to that. If any issues: <br /> https://docs.docker.com/network/proxy/ <br /> https://docs.docker.com/config/daemon/systemd/ 
    - `systemctl daemon-reload` should always be accompanied (before) with `systemctl restart docker` for any changes in the docker config files and `Dockerfile`.
    
3. **`salt_minion_docker.sh`**:
    - Builds a *masterless salt-minion* container with default parameters with image name as `salt-minion`.
    - Uses `Dockerfile` from `salt-minion` folder of this repository, so directory structure should be preserved as it is.
    - Proxy *ENV* variables are set into the *Dockerfile*. 
    - Proxy addresses from `.gitignore` are used for the above *ENV* varaibles and for `/etc/salt/minion` minion file(inside container). This script is dependent on *Dockefile* structure especially with *RUN* command. Caution while changing the *Dockerfile*.
    - *Test pings* the latest *salt-minion* image build in the foreground.

4. **`run_salt_states.sh`**:
    - *Runs* and *Execs* salt states the latest *salt-minion* image.
    - Container is mapped with a *local volume* (outside container): `/root/devops-salt-container/salt-states`. Salt states are placed in this local volume and are executed inside container.
    - Runs the container in background and executes the salt-states on the same by taking a command line argument (Check master README.md).

5. **`.gitignore`**:
    - Contains proxy addresses and proxy ports.
    - *Please update your proxies before running any of the scripts.*
    - Its pre-set to the above mentioned proxy address and port.
    - Scripts do not handle address masks (which when specified with the IP address) and more than one IP address and port.
    - Scripts are space and case sensitive. 