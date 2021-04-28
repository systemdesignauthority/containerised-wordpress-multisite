#!/bin/bash
# Install wordpress-lemps
# systemdesignauthority.com
# 22-04-2021
# Version 1

# Playbook

# Install all required dependencies for docker-compose
./docker-compose_dependencies.sh
[ $? -eq 0 ] && : || exit 1

# Ensure dependencies are met for certbot
./certbot_dependencies.sh
[ $? -eq 0 ] && : || exit 1

# Install certificate
./certificate_install.sh
[ $? -eq 0 ] && : || exit 1

# Install mysql, wordpress, webserver, certbot for production
./production_install.sh
[ $? -eq 0 ] && : || exit 1

# Configure host security
./hostsecurity_configure.sh
[ $? -eq 0 ] && : || exit 1
