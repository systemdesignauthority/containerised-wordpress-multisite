#!/bin/bash
# Ensure dependencies are met for certbot
# systemdesignauthority.com
# 21-04-2021
# Version 1
# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "certbot_dependencies.sh Ensure dependencies are met for certbot"
echo "Please refer to systemdesignauthority.com/projects/wordpress-lemps for more information"
# Prompt user for domain
echo -n "Please enter you domain (eg: yourdomain.com or yourdomain.co.uk) and then press [ENTER]: "
read domain

# Ensure given domain is resolving to this computer's public IP
thisPublicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
thisDomainARecord=$(dig +short $domain)
if [ "$thisPublicIP" != "$thisDomainARecord" ]
    then
        echo $domain "does not resolve to this servers public IP Address. Please see the DNS A record section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
    exit
fi

# Ensure port fowarding is in place
# port 80 for SCEP
echo "Listening for http (port 80) at" $domain "from another public network, ie, a smartphone on a mobile network"
touch _80-out
tcpdump -i any dst port 80 -vvv -l > _80-out 2>&1 &
i=0
until [ "$(cat _80-out | grep $domain)" ]
do
    sleep 1
    echo -n "."
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Nothing received on http (port 80) for 60 seconds. Please see the port forwarding section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
       exit
    fi
done
kill $!
rm -f _80-out
echo "Success! Port forwarding working OK for port 80"

#port 443 for https
echo "Listening for https (port 443) at" $domain "from another public network, ie, a smartphone on a mobile network"
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
       echo "Nothing received on https (port 443) for 60 seconds. Please see the port forwarding section at systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
       exit
    fi
done
kill $!
rm -f _443-out
echo "Success! Port forwarding working OK for port 443"

#confirm
echo "Dependencies are met for certbot"
