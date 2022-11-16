#!/bin/bash

#Clear the terminal
clear

#List the console keyboard layouts
ls /usr/share/kbd/keymaps/**/*.map.gz

#Set the console keyboard layout
loadkeys us

#Verify your internet connection
ping google.com -c 4

#Update the system clock
timedatectl set-ntp true

#Update the pacman database
pacman -Syy

#Install the required package for the next step
pacman -S reflector

#Setting up mirrors for optimal download
reflector -c Australia -a 6 --sort rate --save /etc/pacman.d/mirrorlist

#Update the pacman database
pacman -Syy 

#List information about all available block devices
lsblk

#Create the partitions
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
g   #Create a new GPT disklabel
n   #Create the first partition, this will be our efi partition
    #Default
    #Default
+1G #Define the size of the parition
t   #Change the filesystem to EFI
1   #EFI filesystem
n   #Create the second partition, this will be our root partition
    #Default
    #Default
    #Default
w   #Write the changes to the disk
EOF

#Format /dev/sda1 with Fat Filesystem
mkfs.fat -F32 /dev/sda1

#Format /dev/sda2 with ext4 filesystem
mkfs.ext4 /dev/sda2

#Mount the installation partition
mount /dev/sda2 /mnt

#Create the boot directory
mkdir /mnt/boot

#Mount the boot partition
mount /dev/sda1 /mnt/boot

#List information about all available block devices
lsblk

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

#Install the Base System
pacstrap /mnt base linux linux-firmware nano

#Generate the filesystem table where the mount points will be stored
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

#Move into the installation partition and leave the ISO installer
arch-chroot /mnt

#Create a swap file for the system
fallocate -l 2GB /swapfile

#Change the permissions on the swap file so that it can be read
chmod 600 /swapfile

#Create the swap
mkswap /swapfile

#Activate the swap
swapon /swapfile

#Put the swapfile in the fstab file
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

#List all available timezones
timedatectl list-timezones

#Set your timezone
ln -sf /usr/share/zoneinfo/Australia/Brisbane /etc/localtime

#Synchronize the harware clock to the system clock
hwclock --systohc

#Set the locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

#Generate the locale
locale-gen

#Add your locale to locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

#Save your keyboard layout
echo "KEYMAP=us" >> /etc/vconsole.conf

#Edit the hostname
echo "telstra" >> /etc/hostname

#Edit the hosts file
echo "                                               "  >  /etc/hosts
echo "#Static table lookup for hostnames.            "  >> /etc/hosts
echo "#See hosts(5) for details.                     "  >> /etc/hosts
echo "127.0.0.1		localhost                        "  >> /etc/hosts
echo "::1           localhost                        "  >> /etc/hosts
echo "127.0.1.1     telstra.localdomain       telstra"  >> /etc/hosts

#Set the root password
passwd root << EOF
blackarch
blackarch
EOF

#Install the required packages for the grub bootloader
pacman -S grub efibootmgr networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober base-devel linux-headers reflector git bluez bluez-utils cups xdg-utils xdg-user-dirs --noconfirm

#Install the grub bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

#Generate the configuration file for grub
grub-mkconfig -o /boot/grub/grub.cfg

#Create a new user and add it to the following groups
useradd -mG wheel,audio,video,optical,storage user

#Give the username a password
passwd user << EOF
blackarch
blackarch
EOF

#Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi

#Installing graphics drivers
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

#Install the display server
pacman -S xorg

#Install login manager
pacman -S sddm

#Enable the service
systemctl enable sddm

#Install the KDE desktop environment
pacman -S plasma kde-applications packagekit-qt5

#Change boot target to the GUI mode
systemctl set-default graphical.target

#Enable services to start at boot
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable org.cups.cupsd

#Exit the installation
exit

#Unmount the partitions
umount -a

#Reboot the system
reboot
