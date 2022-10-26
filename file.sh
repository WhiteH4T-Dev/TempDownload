#!/bin/bash

echo ""
echo "This installation is for UEFI. Press [Enter] to continue..."
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
read -p "Timezone (Region/City): " A2
ln -sf /usr/share/zoneinfo/${A2} /etc/localtime

#Syncronize the Hardware Clock to the System Clock
hwclock --systohc

#Set the Locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

#Setup Hostname
read -p "Enter your hostname: " A3
echo "${A3}" >> /etc/hostname 

#Edit the hosts file
echo "" > /etc/hosts
echo "#Static table lookup for hostnames.          " >> /etc/hosts
echo "#See hosts(5) for details.                   " >> /etc/hosts
echo "127.0.0.1		localhost                  " >> /etc/hosts
echo "::1		    localhost                  " >> /etc/hosts
echo "127.0.1.1		${A3}.localdomain       ${A3}" >> /etc/hosts
clear

#Change the Root Password
passwd root

#Create a new user and add it to the groups
read -p "What username do you want? " A4
useradd -mG wheel,audio,video,optical,storage ${A4}
#Give the username a password
passwd ${A4}
# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Install Networking Tools
pacman -S efibootmgr networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers
systemctl enable NetworkManager

#Install Microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi

#Installing Graphics Drivers
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed nvidia
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi

#Install Grub
sudo pacman -S grub
#Create an EFI directory in our Boot directory
mkdir /boot/EFI
#Mount the EFI partition
mount /dev/${BLOCK_DEVICE}1 /boot/EFI
#Run the Grub Install 
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
#Create a Grub Configuration file
grub-mkconfig -o /boot/grub/grub.cfg

#Exit the installation
umount -l /mnt
shutdown now
