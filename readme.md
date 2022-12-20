# Installation
## Fedora Server
Language: English US
Keyboard: German (no dead keys)
Hostname: orontes
Packets: Headless server...
User: cfolkers
Disk:
    btrfs volume
        @ subvolume for /
        @home subvolume for /home
        @var subvolume for /var

## auto updates:
sudo dnf install dnf-automatic
/etc/dnf/automatic.conf
    apply_updates = yes
sudo systemctl enable --now dnf-automatic.timer

## snapper:
sudo dnf install snapper python3-dnf-plugin-snapper
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mkdir /mnt/btrfs
sudo mount /dev/sda3 -o subvolid=5 /mnt/btrfs
cd /mnt/btrfs
sudo btrfs subvolume create @snapshots
cd ..
sudo umount /mnt/btrfs
sudo rmdir btrfs/
/etc/fstab
    UUID=<same uuid as /> /.snapshots btrfs subvol=@snapshots 0 0
sudo systemctl daemon-reload
sudo mount -a
sudo btrfs subvolume list / | grep "@$"
sudo btrfs subvolume set-default <ID of subvolume for /> /
sudo grubby --update-kernel=ALL --remove-args="rootflags=subvol=@"
/etc/updatedb.conf
    PRUNENAMES = ".snapshots"
sudo snapper set-config TIMELINE_LIMIT_YEARLY=0
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
documentation:
    https://craftycoder.com/blog/fedora-snapper/

## data
sudo semanage fcontext -a -t snapperd_data_t "/srv/\.snapshots(/.*)?"
sudo mkfs.btrfs /dev/sdb
sudo mkdir /mnt/btrfs
sudo mount /dev/sdb /mnt/btrfs
cd /mnt/btrfs
sudo btrfs subvolume create @srv
cd ..
sudo umount /mnt/btrfs
sudo rmdir btrfs/
/etc/fstab
    UUID=<uuid> /srv btrfs subvol=@srv 0 0
sudo systemctl daemon-reload
sudo mount -a
sudo snapper -c data create-config /srv
sudo snapper -c data set-config NUMBER_LIMIT=3

## backup
sudo dnf install rdiff-backup hdparm udisks
sudo cp backup.timer /etc/systemd/system/
sudo cp backup.service /etc/systemd/system/
sudo cp manual_backup.service /etc/systemd/system/
sudo cp backup.rules /etc/udev/rules.d/
sudo cp backup.sh /opt/
sudo cp manual_backup.sh /opt/
sudo chmod a+x /opt/backup.sh
sudo chmod a+x /opt/manual_backup.sh
sudo mkdir /mnt/daily_backup
sudo mkdir /mnt/manual_backup
sudo systemctl enable --now backup.timer
sudo udevadm control --reload

documentation:
    run backup:
        sudo systemctl start backup
    format disks without partition table as ext4 label "Daily Backup N"
    sudo udevadm info /dev/sd? | grep ID_SERIAL_SHORT


## srv:
```
sudo dnf install docker docker-compose
```
```bash
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
```
manually set the nameservers, by creating a new `/etc/resolv.conf`.
Copy docker files from repo into `/srv`

```bash
sudo systemctl enable --now docker
cd /srv/traefik
sudo docker-compose pull
sudo docker-compose up -d
cd /srv/pihole
sudo docker-compose pull
sudo docker-compose up -d
sudo docker-compose down
# add static domains into etc-pihole/custom.list
sudo docker-compose up -d
cd /srv/psql
sudo docker-compose pull
sudo docker-compose up -d
sudo chattr +C /srv/psql/data
# create databases for nextcloud and paperless
sudo docker exec -ti -u postgres psql bash
psql
create database paperless;
create user paperless with encrypted password 'mypass';
grant all privileges on database paperless to paperless;
create database nextcloud;
create user nextcloud with encrypted password 'mypass';
grant all privileges on database nextcloud to nextcloud;
create database mealie;
create user mealie with encrypted password 'mypass';
grant all privileges on database mealie to mealie;
\q
exit

cd /srv/nextcloud
sudo docker-compose pull
sudo docker-compose up -d
#visit website and configure database
db_user: nextcloud
db_pw: 'mypass'
db_name: nextcloud
db_host: psql:5432

cd /srv/paperless
sudo docker-compose pull
sudo docker-compose up -d
sudo docker-compose run --rm webserver createsuperuser

cd /srv/mealie
sudo docker-compose pull
sudo docker-compose up -d

sudo firewall-cmd --permanent --zone=FedoraServer --add-service=https
sudo firewall-cmd --permanent --zone=FedoraServer --add-service=http
sudo firewall-cmd --permanent --direct --add-chain ipv4 filter DOCKER-USER
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -d 192.168.178.0/16 -m conntrack --ctstate NEW -j DROP
sudo firewall-cmd --reload

sudo cp /srv/update.sh /opt/
sudo chmod a+x /opt/update.sh
sudo cp /srv/update.timer /etc/systemd/system/
sudo cp /srv/update.service /etc/systemd/system/
sudo systemctl enable --now update.timer
```

documentation:
    sudo docker image prune -f
    run occ:
        sudo docker exec -ti --user www-data srv_app_1 /var/www/html/occ
    run mysql:
        sudo docker exec -ti srv_db_1 mysql -p
        sudo docker exec -i srv_nextcloud-db_1 mysql -uroot -ppassword nextcloud < nextclouddb.sql
    clear firewall:
        sudo firewall-cmd --permanent --direct --remove-chain ipv4 filter DOCKER-USER
        sudo firewall-cmd --permanent --direct --remove-rules ipv4 filter DOCKER-USER