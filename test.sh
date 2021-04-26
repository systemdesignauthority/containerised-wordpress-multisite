#!/bin/bash

echo "$USER"


(crontab -l -u "$USER" 2>&1 ; echo "0 4 * * 6 ~/wordpress-lemps/certificate_renew.sh >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -
