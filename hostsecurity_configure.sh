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
iptables -F

# Allow apt for security updates
#sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -d 192.168.0.0/24 -j DROP
sudo iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow ssh from a specific host on the LAN
iptables -A INPUT -p tcp -s 192.168.0.201 --dport 22 -j ACCEPT

# Deny all unknown traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Deny all icmp
sudo sed -i '/ufw-before-input.*icmp/s/ACCEPT/DROP/g' /etc/ufw/before.rules

