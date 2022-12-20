#!/bin/bash

set -e
mount /dev/daily_backup /mnt/daily_backup
NUMBER=$(snapper -c data create -c number -p -d "Daily Backup")
rdiff-backup /srv/.snapshots/$NUMBER/snapshot/ /mnt/daily_backup/srv_backup/
rdiff-backup --remove-older-than 4W --force /mnt/daily_backup/srv_backup/
umount /mnt/daily_backup
hdparm -y /dev/daily_backup