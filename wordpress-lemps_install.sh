#!/bin/bash
# Install wordpress-lemps
# systemdesignauthority.com
# 10-04-2021
# Version 1

function genpw {
    echo $(dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-24)
}

# Prompt user for domain
#echo "This program will setup wordpress-lamps for one domain eg: yourdomain.com or yourdomain.co.uk"
#echo -n "Enter you domain and then press [ENTER]: "
#read domain
domain="systemsdesignauthority.co.uk"

# Ensure given domain is resolving to this computer's public IP
thisPublicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
thisDomainARecord=$(dig +short $domain)
if [ "$thisPublicIP" != "$thisDomainARecord" ]
    then
        echo $domain "does not resolve to this devices public IP Address. Please see the DNS A record section in this blog. Setup cannot continue."
    exit
fi



# Generate .env file
 rm -f .env
 echo "MYSQL_ROOT_PASSWORD="$(genpw) >> .env
 echo "MYSQL_USER="$(genpw) >> .env
 echo "MYSQL_PASSWORD="$(genpw) >> .env
#echo "DOMAIN="$domain >> .env



# Ensure port forwarding is implemented by requesting certificates using certbot for this domain
# Create docker-compose and nginx configurations using steps 1-3 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
# docker-compose config
rm -f docker-compose.yml
sed "s/this_domain/$domain/g" docker-compose_staging.yml > docker-compose.yml
# nginx config
rm -f nginx-conf/nginx.conf
sed "s/this_domain/$domain/g" nginx-conf/nginx_staging.conf > nginx-conf/nginx.conf
# Launch nginx and certbot to stage certificates using step 4 from https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose
docker-compose up -d
# Ensure that the Lets Encrypt provided certificates are valid for this domain
# When certbot exits
until [ "$(docker-compose ps certbot | grep -o Exit)" = "Exit" ]
do
    sleep 5 
done
# Check status of the certs
if [ "$(cat var/log/letsencrypt/letsencrypt.log | grep OCSPCertStatus.GOOD | grep -o $domain)" != "$domain" ]
    then
        echo $domain "cannot be reached on this device from the internet. Please see the port forwarding section in this blog. Setup cannot continue."
    exit
fi

echo "the end"