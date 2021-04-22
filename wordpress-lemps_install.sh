#!/bin/bash
# Install wordpress-lemps
# systemdesignauthority.com
# 22-04-2021
# Version 1

# Playbook
./docker-compose_dependencies.sh
[ $? -eq 0 ] && echo "" || exit

./certbot_dependencies.sh
[ $? -eq 0 ] && echo "" || exit

./certificate_install.sh
[ $? -eq 0 ] && echo "" || exit
