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

# Welcome
echo "hostsecurity_configure.sh | Configure host security"
echo "Please refer to systemdesignauthority.com/projects/wordpress-lemps for more information"

# Get server info
#dns servers
i=0
while read -r dns
do
   i=$((i+1))
   dns[$i]=$dns
done < <(systemd-resolve --status | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' | sort - | uniq -)
dns1=${dns[1]}
dns2=${dns[2]}
#ethernet name
eth=$(ip route get $dns1 | grep -oP '(?<=dev )[^ ]*')
#ip address
ip=$(ip route get $dns1 | grep -oP '(?<=src )[^ ]*')
#ssh client for managing this ssh server
echo "Please enter ssh client IP address (eg 192.168.0.200) or leave blank, then press [Enter]"
read ssh
good_ssh="$( echo $ssh | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' )"
#local LAN subnet
echo "Please enter local subnet IP address and mask (eg 192.168.0.0/24), then press [Enter]"
read subnet
good_subnet="$( echo $subnet | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/..' )"
if test -z "$good_subnet"
then
   echo "Subnet not recognised. Please see systemdesignauthority.com/projects/wordpress-lemps. Setup cannot continue."
   exit 1
fi

# Reset
sudo ufw disable
sudo iptables --flush
sudo iptables --delete-chain
sudo service docker restart

# Allow all loopback traffic
sudo iptables -A INPUT -i lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
sudo iptables -A OUTPUT -o lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT

# Allow ssh from a specific host on the LAN
[ -z "$good_ssh" ] && : || sudo iptables -A INPUT -i $eth -p tcp -s $ssh -d $ip --dport 22 -j ACCEPT
[ -z "$good_ssh" ] && : || sudo iptables -A OUTPUT -p tcp -s $ip -d $ssh --sport 22 -j ACCEPT

# Drop all other LAN traffic
sudo iptables -A INPUT -i $eth -s $subnet -d $subnet -j DROP
sudo iptables -A OUTPUT -s $subnet -d $subnet -j DROP

# Allow domains from apt sources for security updates
for domain in $(cat /etc/apt/sources.list | grep -Eo '(http|https)://[^/"]+' | sed 's/https\?:\/\///' | uniq -) ; do
   sudo iptables -A OUTPUT -s $ip -d $domain -j ACCEPT
   sudo iptables -A INPUT -i $eth -s $domain -d $ip -m state --state RELATED,ESTABLISHED -j ACCEPT
done

# Allow project updates and nginx security parameters
sudo iptables -A OUTPUT -s $ip -d github.com -j ACCEPT
sudo iptables -A INPUT -i $eth -s github.com -d $ip -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -s $ip -d raw.githubusercontent.com -j ACCEPT
sudo iptables -A INPUT -i $eth -s raw.githubusercontent.com -d $ip -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow DNS
sudo iptables -A OUTPUT -s $ip -d $dns1 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -s $ip -d $dns2 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -s $ip -d $dns1 -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -s $ip -d $dns2 -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i $eth -s $dns1 -d $ip -p udp --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i $eth -s $dns2 -d $ip -p udp --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i $eth -s $dns1 -d $ip -p tcp --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i $eth -s $dns2 -d $ip -p tcp --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP

# Lockdown IPv6
ipt6="/sbin/ip6tables"
$ipt6 -F
$ipt6 -X 
$ipt6 -Z
$ipt6 -P INPUT DROP
$ipt6 -P FORWARD DROP
$ipt6 -P OUTPUT DROP

# cron for security updates
(crontab -l -u "$USER" 2>&1 ; echo "0 4 * * 6 ~/wordpress-lemps/certificate_renew.sh >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -

# Save
sudo /sbin/iptables-save
sudo /sbin/ip6tables-save

# monitor
# sudo watch -n 2 -d iptables -nvL
