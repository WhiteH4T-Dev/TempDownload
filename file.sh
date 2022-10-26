#!/bin/bash

echo ""
echo "This installation is for UEFI. Press [Enter] to continue..."
#Clear the terminal screen
clear

#Ask the questions
read -p "Set the console keyboard layout: " A1
read -p "What disk do you want to partition? " BLOCK_DEVICE
read -p "Timezone (Region/City): " A2



#Verify the boot mode
efi_boot_mode(){
    # if the efivars directory exists we definitely have an EFI BIOS
    # otherwise, we could have a non-standard EFI or even an MBR-only system
    ( $(ls /sys/firmware/efi/efivars &>/dev/null) && return 0 ) || return 1
}

if $(efi_boot_mode); then 
    clear
else
    echo "MBR is not supported"
    exit
fi

#Set the console keyboard layout
ls /usr/share/kbd/keymaps/**/*.map.gz
if [ -z "$A1" ]; then
    loadkeys us
else
    loadkeys $A1
fi

#Update the system clock
timedatectl set-ntp true
timedatectl status

#Create the Partitions
lsblk
fdisk /dev/${BLOCK_DEVICE} << EOF
m
g
m
n
1

+550M
n
2

+2G
n
3


m
t
1
1
t
2
19
w
EOF
lsblk

#Format the Partitions
mkfs.fat -F32 /dev/${BLOCK_DEVICE}1
mkswap /dev/${BLOCK_DEVICE}2
swapon /dev/${BLOCK_DEVICE}2
mkfs.ext4 /dev/${BLOCK_DEVICE}3

#Mount the Paritions
mount /dev/${BLOCK_DEVICE}3 /mnt

#Install the Base System
pacstrap /mnt base linux linux-firmware nano

#Generate our Filesystem Table
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

#Change root into the new system
arch-chroot /mnt

#Set the Timezone
ls /usr/share/zoneinfo
ln -sf /usr/share/zoneinfo/$A2 /etc/localtime
