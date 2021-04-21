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

# Prompt user for domain
echo "This program will check the dependencies for certbot for one domain eg: yourdomain.com or yourdomain.co.uk"
echo -n "Enter you domain and then press [ENTER]: "
#read domain
domain="systemsdesignauthority.co.uk"

# Ensure given domain is resolving to this computer's public IP
thisPublicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
thisDomainARecord=$(dig +short $domain)
if [ "$thisPublicIP" != "$thisDomainARecord" ]
    then
        echo $domain "does not resolve to this servers public IP Address. Please see the DNS A record section in this blog. Setup cannot continue."
    exit
fi

# Ensure port fowarding is in place
# port 80 for SCEP
echo " "
echo "http port 80 needs to be forwarded to this server for certificate management. Please refer to the port forwarding section of this blog for information."
echo "Listening for http requests to" $domain "from another public network, ie, a smartphone on a mobile network"
rm -f _80-out
touch _80-out
tcpdump -i any dst port 80 -U -w _80-out &
i=0
until [ "$(cat _80-out | grep $domain)" ]
do
    sleep 1
    echo -n "."
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Nothing received on port 80 for 60 seconds."
       echo "Please refer to the port forwarding section of this blog. Setup cannot continue."
       exit
    fi
done
kill $!
rm -f _80-out
echo "Received traffic for" $domain "on port 80"
echo "Success! Port forwarding working OK for port 80"

#port 443 for https
echo " " 
echo "This server uses https. Please refer to the port forwarding section of this blog for information."
echo "Listening for https requests to" $domain "from another public network, ie, a smartphone on a mobile network"
rm -f _443-out
touch _443-out
tcpdump -i any dst port 443 -l > _443-out &
i=0
until [ "$(cat _443-out | grep https)" ]
do
    sleep 1 
    echo -n "."
    ((i++))
    if [ $i = 60 ]; then
       echo " "
       echo "Nothing received on port 443 for 60 seconds."
       echo "Please refer to the port forwarding section of this blog. Setup cannot continue."
       exit
    fi
done
kill $!
rm -f _443-out
echo "Received traffic on port 443"
echo "Success! Port forwarding working OK for port 443"

#confirm
echo " "
echo "Success!"
echo $domain "resolves to this servers public IP Address"
echo "Port forwarding working OK for port 80"
echo "Port forwarding working OK for port 443"

