#!/bin/bash


(
    set -e
    mount /dev/daily_backup /mnt/daily_backup
    NUMBER=$(snapper -c data create -c number -p -d "Daily Backup")
    rdiff-backup /srv/.snapshots/$NUMBER/snapshot/ /mnt/daily_backup/srv_backup/
)
errorCode=$?
if [ $errorCode -eq 0 ]; then
    rdiff-backup --remove-older-than 4W --force /mnt/daily_backup/srv_backup/
fi
umount /mnt/daily_backup
hdparm -y /dev/daily_backup
exit $errorCode
