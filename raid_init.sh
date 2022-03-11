#!/bin/bash
wipefs --all --force /dev/sd{b,c,d,e,f,g}
wipefs --all --force /dev/nvme0n[1-5]
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=6 /dev/sd{b,c,d,e,f,g}
mdadm --create --verbose /dev/md1 --level=5 --raid-devices=5 /dev/nvme0n[1-5]
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
mkfs.ext4 /dev/md0 -L md0
mount /dev/md0 /mnt
echo 'LABEL=md0 /mnt ext4  defaults  1 1' >> /etc/fstab