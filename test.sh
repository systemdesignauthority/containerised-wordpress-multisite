#!/bin/bash

#echo "$USER"


#(crontab -l -u "$USER" 2>&1 ; echo "0 4 * * 6 ~/wordpress-lemps/certificate_renew.sh >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -




this_IP=""
fw_IPs=""

# Get IP addresses used by apt from the domains in /etc/apt/sources.list
ubuntu_sources_domains=$(cat /etc/apt/sources.list | grep -Eo '(http|https)://[^/"]+' | uniq -)
for fqdn in ${ubuntu_sources_domains[@]}; do
   this_domain="$( echo $fqdn | sed 's/https\?:\/\///' )"
   this_IP="$( dig +short $this_domain | uniq - ) "
   apt_IPs+=$this_IP
done

# Check IP is formated correctly then write the firewall rule
for ip in ${apt_IPs[@]}; do
   check_ip="$( echo $ip | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' )"
   [ -z "$check_ip" ] && : || echo "sudo iptables -A OUTPUT -d " $check_ip "-m state --state NEW -j ACCEPT"	
done



# Get server info
#dns
i=0
while read -r dns
do
   i=$((i+1))
   dns[$i]=$dns
done < <(systemd-resolve --status | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' | sort - | uniq -)
dns1=${dns[1]}
dns2=${dns[2]}
#eth
eth=$(ip route get $dns1 | grep -oP '(?<=dev )[^ ]*')

ip=$(ip route get $dns1 | grep -oP '(?<=src )[^ ]*')

echo "Please enter ssh IP address or leave blank, then press [Enter]"
read ssh
check_ip="$( echo $ssh | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' )"
   [ -z "$check_ip" ] && ssh="" || :  




echo dns1 $dns1
echo dns2 $dns2
echo eth $eth
echo ip $ip
echo ssh $ssh
