#Partition your Disks
lsblk
read -p "Disk: " A1
fdisk $A1 << EOF
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
