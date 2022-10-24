#!/bin/bash

clear
echo "-------------------------------------------------------------------------"
echo "Arch Linux - Installation"
echo "-------------------------------------------------------------------------"
echo ""
read -p "Are you sure you want to proceed? No crying later!"
clear
#Synchronize your Network Time Protocol
timedatectl set-ntp true
timedatectl status
#Create your Partitions
lsblk
echo ""
fdisk /dev/vda << EOF
g
n


+500M
t
L
1
n
2


w
EOF
clear
lsblk
#Format the Partitions
mkfs.fat -F32 /dev/vda1
mkfs.ext4 /dev/vda2
clear
lsblk
#Mount the Paritions
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot
clear
lsblk
clear
#Install the Base System
pacstrap /mnt base linux linux-firmware nano
clear
#Generate our Filesystem Table
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
#Change root into the new system
arch-chroot /mnt
#Create Swap File
fallocate -l 2GB /swapfile
#Change the permissions of the file
chmod 600 /swapfile
#Activate the file
mkswap /swapfile
swapon /swapfile
#Place the Swapfile in the Fstab File
echo "" >> /etc/fstab
echo "/swapfile none swap defaults 0 0" >> /etc/fstab
clear
#Localization
#Set the Timezone
ls /usr/share/zoneinfo | less
read -p "Timezone (Region/City): " A2
#Create a symbolic link 
ln -sf /usr/share/zoneinfo/$A2 /etc/localtime
#Syncronize the Hardware Clock to the System Clock
hwclock --systohc
#Work on Locale.gen
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
#And last
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
clear
#Setup Hostname
echo "arch" >> /etc/hostname 
#Edit the hosts file
echo "" > /etc/hosts
echo "#Static table lookup for hostnames.          " >> /etc/hosts
echo "#See hosts(5) for details.                   " >> /etc/hosts
echo "127.0.0.1		localhost                  " >> /etc/hosts
echo "::1		localhost                  " >> /etc/hosts
echo "127.0.1.1		arch.localdomain       arch" >> /etc/hosts
clear
passwd root
clear
#Install Networking Tools
pacman -S efibootmgr networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers
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
#Install the System-D Bootloader
bootctl --path=/boot install
clear
#Edit 2 files for System-D Boot to work
cd /boot/
ls
cd loader
ls
echo "" > loader.conf
echo "timeout 3" >> loader.conf
echo "#console-mode keep" >> loader.conf
echo "default arch-*" >> loader.conf
clear
#Lets modify the entries
cd entries
ls
touch arch.conf
echo "title	Arch Linux" >> arch.conf
echo "linux	/vmlinuz-linux" >> arch.conf
echo "initrd	/initramfs-linux.img" >> arch.conf
echo "options	root=/dev/vda2 rw" >> arch.conf
cd 
#Enable NetworkManager
systemctl enable --now NetworkManager
#Create a new user and add it to the groups
useradd -mG wheel,audio,video,optical,storage blackarch
#Give the username a password
passwd blackarch
# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
#Exit the system and return to the installer
exit
#Unmount all of the partitions
umount -a
#Reboot
reboot
