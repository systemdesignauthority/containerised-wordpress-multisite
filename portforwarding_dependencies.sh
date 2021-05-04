#!/bin/bash
# Check Port Forwarding for http and https
# systemdesignauthority.com
# 21-04-2021
# Version 1
# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "Check Port Forwarding for http and https"
echo "Please refer to systemdesignauthority.com/projects/containerised-wordpress-multisite for more information"
# Prompt user for domain
echo -n "Please enter you domain (eg: yourdomain.com or yourdomain.co.uk) and then press [ENTER]: "
read domain
rm -f .env
echo "DOMAIN="$domain >> .env

# Ensure given domain is resolving to this computer's public IP
systemd-resolve - -flush-caches
thisPublicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
thisDomainARecord=$(dig +short $domain)
if [ "$thisPublicIP" != "$thisDomainARecord" ]
    then
        echo $domain "does not resolve to this servers public IP Address. Please see the DNS A record section at systemdesignauthority.com/projects/containerised-wordpress-multisite. Setup cannot continue."
    exit 1
fi

# Ensure port fowarding is in place
# port 80 for SCEP
echo "Listening for port 80 at" $domain "from another public network, ie, a smartphone on a mobile network"
rm -f _80-out
touch _80-out
tcpdump -i any dst port 80 -vvv -l > _80-out 2>&1 &
i=0
until [ "$(cat _80-out | grep http)" ]
do
    sleep 1
    echo -n "."
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Nothing received on port 80 for 60 seconds. Please see the port forwarding section at systemdesignauthority.com/projects/containerised-wordpress-multisite. Setup cannot continue."
       exit 1
    fi
done
kill $!
rm -f _80-out
echo "Success! Port forwarding working OK for port 80"

#port 443 for https
echo "Listening for port 443 at" $domain "from another public network, ie, a smartphone on a mobile network"
rm -f _443-out
touch _443-out
tcpdump -i any dst port 443 -l > _443-out 2>&1 &
i=0
until [ "$(cat _443-out | grep https)" ]
do
    sleep 1 
    echo -n "."
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Nothing received on port 443 for 60 seconds. Please see the port forwarding section at systemdesignauthority.com/projects/containerised-wordpress-multisite. Setup cannot continue."
       exit 1
    fi
done
kill $!
rm -f _443-out
echo "Success! Port forwarding working OK for port 443"

#close
echo "Dependencies are met for containerised-wordpress-multisite"
