# File Description and Comments

**Place and run all the scripts in `/root`.**
1. **`init.sh`**
    - init script to start other scripts and read proxy addresses and update them in `installation-scripts/proxy_ip_port.conf` file if needed.
   <br /> 
2. **`install_docker.sh`**: 
    - Installs latest version of *Docker CE* from repository for *Ubuntu 18.04 Server* as the underlying system.
    - If this error occurs (which will not be caught by `set -e`): *'Release file not yet valid'*, please use `timedatectl` to sync your system time with *NTP* and reboot the system.
    <br />
3. **`configure_docker.sh`**:
    - Configures the Docker environment required to build and run *SaltStack* images. 
    - Sets *proxy* addresses at various places obtianed from `installation-scripts/proxy_ip_port.conf`.
    - If any *DNS* address issue faced, set your *DNS* addresses in `/etc/default/docker` file at line: `DOCKER_OPTS="..."`
    - This script creates *docker.service.d* for proxy setup. `http_proxy.conf` is created and used to that. If any issues: <br /> https://docs.docker.com/network/proxy/ <br /> https://docs.docker.com/config/daemon/systemd/ 
    - `systemctl daemon-reload` should always be accompanied (before) with `systemctl restart docker` for any changes in the docker config files and `Dockerfile`.
    <br />
4. **`salt_minion_docker.sh`**:
    - Builds a *masterless salt-minion* container with default parameters with image name as `<distribution>-salt-minion`; Example: `centos-salt-minion`.
    - Uses `Dockerfile` from `salt-minion` folder of this repository, so directory structure should be preserved as it is.
    - Proxy *ENV* variables are set into the *Dockerfile* and for the container as well.
    - Dockerfile is made idempotent and some of the commands in this script are dependent on the Dockerfile structure. Caution while changing the *Dockerfile*.
    - *Test pings* the latest *salt-minion* image build in the foreground.
    <br />
5. **`run_salt_states.sh`**:
    - *Runs* and *Execs* salt states the latest *salt-minion* image.
    - Container is mapped with a *local volume* (outside container): `/root/devops-salt-container/salt-states`. Salt states are placed in this local volume and are executed inside container.
    - Runs the container in foregroud and logs the user into the container by default.
    <br />
6. **`proxy_ip_port.conf`**:
    - Contains proxy addresses and proxy ports.
    - *Please update your proxies while running the script when prompted to.*