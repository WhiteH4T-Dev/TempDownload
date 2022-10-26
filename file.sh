#!/bin/bash
#This installation is for UEFI

#Clear the terminal screen
clear

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
read -p "Set the console keyboard layout: " A1
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
read -p "What disk do you want to partition? " BLOCK_DEVICE
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
