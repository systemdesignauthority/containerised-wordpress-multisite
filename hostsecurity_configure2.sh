#!/bin/bash
# Configure host security
# systemdesignauthority.com
# 26-04-2021
# Version 1

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Reset
#sudo iptables --flush
#sudo iptables --delete-chain

sudo iptables -F ufw-before-input
sudo iptables -F ufw-before-output

# Allow ssh from a specific host on the LAN
sudo iptables -A ufw-before-input -p tcp -s 192.168.0.200 --dport 22 -j ACCEPT
sudo iptables -A ufw-before-output -p tcp -d 192.168.0.200 --sport 22 -j ACCEPT

# Allow apt for security updates
sudo iptables -A ufw-before-output -d 192.168.0.0/24 -j DROP
sudo iptables -A ufw-before-output -p tcp --dport 80 -m state --state NEW -j ACCEPT
sudo iptables -A ufw-before-output -p tcp --dport 443 -m state --state NEW -j ACCEPT
sudo iptables -A ufw-before-output -p tcp --dport 53 -m state --state NEW -j ACCEPT
sudo iptables -A ufw-before-output -p udp --dport 53 -m state --state NEW -j ACCEPT
sudo iptables -A ufw-before-input -m state --state RELATED,ESTABLISHED -j ACCEPT

# Deny all icmp
sudo iptables -A ufw-before-input -p icmp --icmp-type any -j DROP
sudo iptables -A ufw-before-output -p icmp -j DROP

# Default policies
#sudo iptables -P ufw-before-input DROP
#sudo iptables -P FORWARD ACCEPT
#sudo iptables -P ufw-before-output ACCEPT
#sudo iptables -A INPUT -i lo -j ACCEPT
#sudo iptables -A OUTPUT -o lo -j ACCEPT

# cron for security updates
#(crontab -l -u "$USER" 2>&1 ; echo "0 4 * * 6 ~/wordpress-lemps/certificate_renew.sh >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -
