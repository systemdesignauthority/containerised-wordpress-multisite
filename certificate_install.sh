#!/bin/bash
# Install certificate
# systemdesignauthority.com
# 22-04-2021
# Version 1

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "certificate_install.sh | Install certificates"
echo "Please refer to systemdesignauthority.com/projects/wordpress-lemps for more information"

# Generate certificates
# create docker-compose and nginx configurations using steps 1-3 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
# retreive domain
domain=$(cat .env | grep DOMAIN | cut -d '=' -f2)
# docker-compose config
rm -f docker-compose.yml
sed "s/this_domain/$domain/g" docker-compose_certs.yml > docker-compose.yml
# nginx config
rm -f nginx-conf/nginx.conf
sed "s/this_domain/$domain/g" nginx-conf/nginx_cert.conf > nginx-conf/nginx.conf
# Launch nginx and certbot to stage certificates using step 4 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
docker-compose up -d > /dev/null 2>&1
# Ensure that the Lets Encrypt provided certificates are valid for this domain
# When certbot exits
i=0
until [ "$(docker-compose ps certbot | grep -o Exit)" = "Exit" ]
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
# Check status of the certs
if ! { [ "$(cat var/log/letsencrypt/letsencrypt.log | grep OCSPCertStatus.GOOD | grep -o $domain)" ] || [ "$(cat var/log/letsencrypt/letsencrypt.log | grep 'Congratulations! Your certificate and chain have been saved')" ]; };
    then
        echo "Certificate installation failed. Please see the certificate section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
    exit
fi
# tidy up
docker-compose down > /dev/null 2>&1

#close
echo "Certificates successfully installed"
