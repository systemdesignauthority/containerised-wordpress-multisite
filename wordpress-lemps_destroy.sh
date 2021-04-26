#!/bin/bash
# Destroy wordpress-lemps
# systemdesignauthority.com
# 26-04-2021
# Version 1

docker-compose down --rmi all -v --remove-orphans
