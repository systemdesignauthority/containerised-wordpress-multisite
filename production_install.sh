#!/bin/bash
# Install mysql, wordpress, webserver, certbot for production
# systemdesignauthority.com
# 23-04-2021
# Version 1

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "production_install.sh | Install mysql, wordpress, webserver, certbot and chron for production"
echo "Please refer to systemdesignauthority.com/projects/wordpress-lemps for more information"

# Install mysql, wordpress, webserver, certbot and chron for production
# create docker-compose and nginx configurations using step 5 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
# Retreive enviromental variables
domain=$(cat .env | grep DOMAIN | cut -d '=' -f2)
MYSQL_ROOT_PASSWORD=$(cat .env | grep MYSQL_ROOT_PASSWORD= | cut -d '=' -f2)
MYSQL_USER=$(cat .env | grep MYSQL_USER | cut -d '=' -f2)
MYSQL_PASSWORD=$(cat .env | grep MYSQL_PASSWORD | cut -d '=' -f2)
# Stop webserver
docker-compose stop webserver #> /dev/null 2>&1
# Get the recommended Nginx security parameters from Certbot using curl
curl -sSLo nginx-conf/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
# docker-compose config
rm -f docker-compose.yml
sed "s/this_domain/$domain/g" docker-compose_production.yml > docker-compose.yml
# nginx config
rm -f nginx-conf/nginx.conf
sed "s/this_domain/$domain/g" nginx-conf/nginx_production.template > nginx-conf/nginx.conf
# Recreate the webserver service
docker-compose up -d --force-recreate --no-deps webserver #> /dev/null 2>&1
# Ensure all services are up
i=0
until [ "$(docker-compose logs db | grep 'ready for connections')" ] && [ "$(docker-compose logs webserver | grep 'ready for start up')" ] && [ "$(docker-compose logs wordpress | grep 'ready to handle connections')" ]
do
    sleep 1
    echo -n "." 
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "wordpress-lemps installation failed. Please see systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
       exit 1
    fi
done

#close
echo "wordpress-lemps successfully installed"

