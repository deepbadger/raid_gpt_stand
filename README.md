# Работа с mdadm
## Результаты ДЗ
* измененный Vagrantfile
* скрипт для создания рейда
* конф для автосборки рейда при загрузке

### Пояснения

1. Выполняем сборку разных raid массивов уровня 5 и 10, на разных типах дисков. Файл конфигурации для автосборки после перезагрузки.
```shell
wipefs --all --force /dev/sd{b,c,d,e,f,g}
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=6 /dev/sd{b,c,d,e,f,g}
wipefs --all --force /dev/nvme0n[1-5]
mdadm --create --verbose /dev/md1 --level=5 --raid-devices=5 /dev/nvme0n[1-5]
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
mkfs.ext4 /dev/md0 -L md0
mount /dev/md0 /mnt
echo 'LABEL=md0 /mnt ext4  defaults  1 1' >> /etc/fstab
```
2. Создаем GPT раздел и 5 партиций
```shell
sgdisk -og /dev/md1
sgdisk -n 0:0:+1MiB -t 0:ef02 -c 0:grub /dev/md1
sgdisk -n 0:0:+20MiB -t 0:ea00 -c 0:boot /dev/md1
sgdisk -n 0:0:+10MiB -t 0:8200 -c 0:swap /dev/md1
sgdisk -n 0:0:+100MiB -t 0:8300 -c 0:home /dev/md1
sgdisk -n 0:0:0 -t 0:8300 -c 0:root /dev/md1
```