#!bin/bash

set -e

# Run the script in root mode

# Set variables
# SALT_PATH here is directory structure dependent and should be retained in the same order for successful build
set_variables()
{
	IP=$(awk -F 'proxy_ip:' '{print $2}' $config_file)
	DOCKER_IP=$(sed -e 's|\/|\\\/|g' <<< "$(awk -F'proxy_ip:' '{print $2}' $config_file)")
        SALT_IP=$(sed -e 's|\\|\\\\|g' <<< $DOCKER_IP)
	PORT=$(awk -F'proxy_port:' '{getline;print $2}' $config_file)
	PROXY="$IP:$PORT"
	DOCKER_PROXY="$DOCKER_IP:$PORT"

	SALT_PATH=$1
	SALT_PROXY_IP="sed -i 's/#proxy_host:.*/proxy_host: $SALT_IP/g' /etc/salt/minion"
	SALT_PROXY_PORT="sed -i 's/#proxy_port:.*/proxy_port: $PORT/g' /etc/salt/minion"
	MINION_FILE="touch \/etc\/salt\/minion"
}

# Restart Docker
# Restarting docker isn't sufficient, it should be accompanied by daemon reload
docker_restart()
{
	echo "Docker Daemon-reloading.."
	systemctl daemon-reload
	echo "Restarting Docker.."
	systemctl restart docker
}

# Set Proxy Variable
# 'source' execution required
export_proxies()
{
	echo Exporting proxies..
	export https_proxy=$PROXY
	export http_proxy=$PROXY
}

# Add ENV, RUN commands to Dockefile
update_proxies()
{
	# Add ENV variables to Dockerfile
	echo Setting proxies...
	sed -i '/FROM .*/a ENV http_proxy "'$DOCKER_PROXY'"\nENV https_proxy "'$DOCKER_PROXY'"' $SALT_PATH/Dockerfile

	# Add proxies for salt-minion inside container
	echo Adding salt-minion proxies...
	sed -i "s|mkdir /srv/salt|&\n\nRUN $MINION_FILE \&\& \\\\\n    $SALT_PROXY_IP \&\& \\\\\n    $SALT_PROXY_PORT|" $SALT_PATH/Dockerfile

}


# Remove if any ENV, RUN commands thats contains proxies
remove_existing_proxies()
{
	echo Removing Proxies if set in Dockerfile..
	sed -i '/ENV http_proxy/d' $SALT_PATH/Dockerfile
	sed -i '/ENV https_proxy/d' $SALT_PATH/Dockerfile
	
	sed -i -e '/proxy_port: .*/,+1d' \
               -e '/proxy_host: .*/d' \
	       -e "/RUN $MINION_FILE .*/d" \
               $SALT_PATH/Dockerfile
}

# Build Docker image
# Tag field is left blank, so docker picks :latest as default
build_image()
{
	docker build -t "$1"-salt-minion $SALT_PATH
}

# Check for build success
check_build_success()
{
	docker image inspect "$1"-salt-minion:latest > /dev/null
	if [ $? -eq 0 ]
	then
    		echo
    		echo Build Successful.
    		echo
	else
    		echo
    		echo Build Unsuccesful.
    		echo
	fi
}

# Run the Docker image
# If some TTY issue raised(like when piping commands), please remove -t option in the below command
ping_test()
{
	echo
	echo Test Pinging minion...
	echo
	docker run -i -t "$1"-salt-minion salt-call --local test.ping
}

######################### MAIN ###############################

# Main function to set the variables, proxies, build images and test
main()
{
	echo
        echo
        echo "############## Building Container Images ###############"
        echo
	echo $1
	echo
		
	if [ $PROXY_FLAG -eq 1 ]
	then
		set_variables "$2"
		remove_existing_proxies
		update_proxies
		docker_restart
		export_proxies
	else
		MINION_FILE="touch \/etc\/salt\/minion"
		SALT_PATH=$2
		remove_existing_proxies
	fi

	echo 
	echo Building $1 Docker image
	build_image "$3"
	check_build_success "$3"
	ping_test "$3"
	source ./run_container.sh
}

case "$option" in
	1)
	IMAGE_NAME="opensuse"
	main "Opensuse 42.3" "/root/devops-salt-container/salt-minion/suse" "$IMAGE_NAME"
	;;
	
	2)
	IMAGE_NAME="ubuntu"
	main "Ubuntu 18.04" "/root/devops-salt-container/salt-minion/ubuntu" "$IMAGE_NAME"
	;;

        3)
	IMAGE_NAME="centos"
	main "Centos 7" "/root/devops-salt-container/salt-minion/centos" "$IMAGE_NAME"
	;;

	*) 
	echo "Unknown option"
	echo "Exiting.."
	exit 1
	;;
esac
