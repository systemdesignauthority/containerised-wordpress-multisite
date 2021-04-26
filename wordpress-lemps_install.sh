#!/bin/bash
# Install wordpress-lemps
# systemdesignauthority.com
# 22-04-2021
# Version 1

# Playbook
# Install all required dependencies for docker-compose
./docker-compose_dependencies.sh
#[ $? -eq 0 ] && : || echo "Installation failed. Please see systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue." exit
# Ensure dependencies are met for certbot
./certbot_dependencies.sh
#[ $? -eq 0 ] && : || echo "Installation failed. Please see systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue." exit
# Install certificate
./certificate_install.sh
#[ $? -eq 0 ] && : || echo "Installation failed. Please see systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue." exit
./production_install.sh

./certificate_renew.sh
