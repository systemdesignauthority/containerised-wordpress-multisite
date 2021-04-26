#!/bin/bash
# Renew certificate
# systemdesignauthority.com
# 26-04-2021
# Version 1

COMPOSE="/usr/local/bin/docker-compose --no-ansi"
DOCKER="/usr/bin/docker"

cd ~/wordpress-lemps
$COMPOSE run certbot renew && $COMPOSE kill -s SIGHUP webserver
$DOCKER system prune -af
