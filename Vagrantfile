# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'open3'
require 'fileutils'

def get_vm_name(id)
  out, err = Open3.capture2e('VBoxManage list vms')
  raise out unless err.exitstatus.zero?

  path = path = File.dirname(__FILE__).split('/').last
  name = out.split(/\n/)
            .select { |x| x.start_with? "\"#{path}_#{id}" }
            .map { |x| x.tr('"', '') }
            .map { |x| x.split(' ')[0].strip }
            .first

  name
end


def controller_exists(name, controller_name)
  return false if name.nil?

  out, err = Open3.capture2e("VBoxManage showvminfo #{name}")
  raise out unless err.exitstatus.zero?

  out.split(/\n/)
     .select { |x| x.start_with? 'Storage Controller Name' }
     .map { |x| x.split(':')[1].strip }
     .any? { |x| x == controller_name }
end


# add NVME disks
def create_nvme_disks(vbox, name)
  unless controller_exists(name, 'NVME Controller')
    vbox.customize ['storagectl', :id,
                    '--name', 'NVME Controller',
                    '--add', 'pcie']
  end

  dir = "../vdisks"
  FileUtils.mkdir_p dir unless File.directory?(dir)

  disks = (0..4).map { |x| ["nvmedisk#{x}_", '1024'] }

  disks.each_with_index do |(name, size), i|
    file_to_disk = "#{dir}/#{name}.vdi"
    port = (i ).to_s

    unless File.exist?(file_to_disk)
      vbox.customize ['createmedium',
                      'disk',
                      '--filename',
                      file_to_disk,
                      '--size',
                      size,
                      '--format',
                      'VDI',
                      '--variant',
                      'standard']
    end

    vbox.customize ['storageattach', :id,
                    '--storagectl', 'NVME Controller',
                    '--port', port,
                    '--type', 'hdd',
                    '--medium', file_to_disk,
                    '--device', '0']

  end
end


def create_disks(vbox, name)
  unless controller_exists(name, 'SATA Controller')
    vbox.customize ['storagectl', :id,
                    '--name', 'SATA Controller',
                    '--add', 'sata']
  end

  dir = "../vdisks"
  FileUtils.mkdir_p dir unless File.directory?(dir)

  disks = (1..6).map { |x| ["disk#{x}_", '1024'] }

  disks.each_with_index do |(name, size), i|
    file_to_disk = "#{dir}/#{name}.vdi"
    port = (i + 1).to_s

    unless File.exist?(file_to_disk)
      vbox.customize ['createmedium',
                      'disk',
                      '--filename',
                      file_to_disk,
                      '--size',
                      size,
                      '--format',
                      'VDI',
                      '--variant',
                      'standard']
    end

    vbox.customize ['storageattach', :id,
                    '--storagectl', 'SATA Controller',
                    '--port', port,
                    '--type', 'hdd',
                    '--medium', file_to_disk,
                    '--device', '0']

    vbox.customize ['setextradata', :id,
                    "VBoxInternal/Devices/ahci/0/Config/Port#{port}/SerialNumber",
                    name.ljust(20, '0')]
  end
end

Vagrant.configure("2") do |config|

config.vm.define "server" do |server|
  config.vm.box = "centos7"
  config.vm.box_url = "https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1804_02.VirtualBox.box"
  server.vm.host_name = 'server'
  server.vm.network :private_network, ip: "10.0.0.41"

  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  server.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
	    cp ~vagrant/.ssh/auth* ~root/.ssh
	    yum install -y mdadm smartmontools hdparm gdisk vim-enhanced
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
        sgdisk -og /dev/md1
        sgdisk -n 0:0:+1MiB -t 0:ef02 -c 0:grub /dev/md1
        sgdisk -n 0:0:+20MiB -t 0:ea00 -c 0:boot /dev/md1
        sgdisk -n 0:0:+10MiB -t 0:8200 -c 0:swap /dev/md1
        sgdisk -n 0:0:+100MiB -t 0:8300 -c 0:home /dev/md1
        sgdisk -n 0:0:0 -t 0:8300 -c 0:root /dev/md1
  SHELL

  server.vm.provider 'virtualbox' do |vbx|
      name = get_vm_name('server')
      create_disks(vbx, name)
      create_nvme_disks(vbx, name)
  end

end

end