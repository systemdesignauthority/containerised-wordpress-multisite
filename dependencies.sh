#!/bin/bash
# Install all required dependencies
# systemdesignauthority.com
# 10-04-2021
# Version 1

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "dependencies.sh | Ensure dependencies are met"
echo "Please refer to systemdesignauthority.com/projects/containerised-wordpress-multisite for more information"

# Update distrubution
echo "Updating..."
sudo apt update -y

# Check if prerequisites are installed and install if not
# Ubuntu 20.04
if [[ $(lsb_release -is) == "Ubuntu" && $(lsb_release -rs) == "20.04" ]]; then

    # Prerequisites for docker-compose in Ubuntu 20.04
    # https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
    # https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04
    declare -a dependencies=("git" "curl" "apt-transport-https" "ca-certificates" "software-properties-common" "docker-ce" "docker-compose")

    # Check and if required install each prerequisite in turn
    for i in "${dependencies[@]}"
    do
        REQUIRED_PKG=$i
        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
        echo Checking for dependency $REQUIRED_PKG... $(echo $PKG_OK | grep -o "installed")
        if [ "" = "$PKG_OK" ]; then
            echo "No $REQUIRED_PKG. Installing $REQUIRED_PKG for" $(lsb_release -is) $(lsb_release -rs)
            if [[ REQUIRED_PKG = "docker-ce" ]]
            then
                curl -4fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
                sudo apt-get update -y
                sudo apt-get --yes install $REQUIRED_PKG
            elif [[ REQUIRED_PKG = "docker-compose" ]]
            then
                sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            else
                sudo apt-get --yes install $REQUIRED_PKG
            fi
        fi
    done
else
    echo "Distribution not detected. Please install dependencies manually. Setup cannot continue."
    exit 1
fi

#close  
echo "Dependencies are met"
