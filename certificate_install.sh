#!/bin/bash
# Install certificate
# systemdesignauthority.com
# 22-04-2021
# Version 1

function genpw {
    echo $(dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-24)
}

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "certificate_install.sh | Install certificates"
echo "Please refer to systemdesignauthority.com/projects/wordpress-lemps for more information"

# Install staging certificates
# create docker-compose and nginx configurations using steps 1-3 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
# Retreive domain
domain=$(cat .env | grep DOMAIN | cut -d '=' -f2)
# Generate .env file
 rm -f .env
 echo "DOMAIN="$domain >> .env
 echo "MYSQL_ROOT_PASSWORD="$(genpw) >> .env
 echo "MYSQL_USER="$(genpw) >> .env
 echo "MYSQL_PASSWORD="$(genpw) >> .env
# docker-compose config
rm -f docker-compose.yml
sed "s/this_domain/$domain/g" docker-compose_certs.yml > docker-compose.yml
# nginx config
rm -f nginx-conf/nginx.conf
sed "s/this_domain/$domain/g" nginx-conf/nginx_cert.template > nginx-conf/nginx.conf
# Launch nginx and certbot to stage certificates using step 4 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
docker-compose up -d #> /dev/null 2>&1
# Ensure that the Lets Encrypt provided certificates are valid for this domain
i=0
until [ "$(docker-compose logs certbot | grep 'You have an existing certificate that has exactly the same domains or certificate name you requested and isn.t close to expiry.')" ] || [ "$(docker-compose logs certbot | grep 'Congratulations! Your certificate and chain have been saved')" ]
do
    sleep 1
    echo -n "." 
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Certificate installation failed. Please see the certificate installation section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
       exit
    fi
done
# Install production certificates
# docker-compose config
sed -i "s/--staging/--force-renewal/g" docker-compose.yml
# Launch nginx and certbot for production certificates using step 4 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
docker-compose up --force-recreate --no-deps certbot #> /dev/null 2>&1
# Ensure that the Lets Encrypt provided certificates are valid for this domain
i=0
until [ "$(docker-compose logs certbot | grep 'You have an existing certificate that has exactly the same domains or certificate name you requested and isn.t close to expiry.')" ] || [ "$(docker-compose logs certbot | grep 'Congratulations! Your certificate and chain have been saved')" ]
do
    sleep 1
    echo -n "." 
    ((i++))
    if [ $i = 60 ] || [ "$(docker-compose logs certbot | grep 'There were too many requests of a given type')" ]; then
       echo " "
       echo "Certificate installation failed. Please see the certificate installation section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
       exit
    fi
done

#close
echo "Certificate successfully installed"

