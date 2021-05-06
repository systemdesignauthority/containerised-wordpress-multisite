#!/bin/bash
# Backup host
# systemdesignauthority.com
# 05-05-2021
# Version 1

# Request sudo if required
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Welcome
echo "backup.sh | Backup docker-host"
echo "Please refer to systemdesignauthority.com/projects/containerised-wordpress-multisite for more information"

# Backup
mkdir -p backup
for container in $(docker ps | grep -v CONTAINER | grep -v ID | cut -c-12) ; do
    # Generate filename
    utc_date=$(date -u +"%FT%H%MZ")
    fn=$container"_"$utc_date
    # backup container
    echo "Backing up $container to backup/container_${fn,,}.tar"
    docker commit -p $container backup/container_${fn,,}
    docker save -o backup/container_${fn,,}.tar backup/container_${fn,,}

    # get volume(s) used in this container
    for path in $(docker inspect -f '{{ .Mounts }}' $container | grep -E -o '/[a-z,/,.,-]+\s') ; do
        if [ $(echo $path | grep -v home) ] ; then
            # backup volume
            safe_path=$(echo "$path" | tr / .)
            echo "Backing up $path in $container to /backup/volume_${safe_path,,}_${fn,,}.tar"
            docker stop $container
 	    docker run --rm --volumes-from $container -v /backup:/backup ubuntu bash -c cd $path && tar -cvf /backup/volume_${safe_path,,}_${fn,,}.tar ./ && rm -fr volume_${safe_path,,}_${fn,,}.tar
            docker start $container
        fi
    done
done

# Check NAS is mounted
sudo mount -t cifs -o user=******,pass=****************,vers=1.0 //192.168.0.234/privateStorage /media/privatestorage

# Backup to NAS
sudo rsync --remove-source-files -a /backup /media/privatestorage/docker-host-backup
sudo rsync --remove-source-files -a backup /media/privatestorage/docker-host-backup

# Create cron for this backup (every Saturday at 3am)
crontab -l > mycron
echo "0 3 * * 6 ~/containerised-wordpress-multisite/backup.sh" >> mycron
crontab mycron
rm mycron

# Close
echo "Backup complete"
