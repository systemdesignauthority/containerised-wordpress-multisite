(crontab -l -u ads ; echo "* * * * * ~/wordpress-lemps/certificate_renew.sh >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -

