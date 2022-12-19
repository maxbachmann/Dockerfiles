#!/bin/bash

set -e
mount /dev/manual_backup /mnt/manual_backup
NUMBER=$(snapper -c data create -c number -p -d "Manual Backup")
rdiff-backup /srv/.snapshots/$NUMBER/snapshot/ /mnt/manual_backup/srv_backup/
rdiff-backup --remove-older-than 3M --force /mnt/manual_backup/srv_backup/
umount /mnt/manual_backup
udisks --detach /dev/manual_backup
