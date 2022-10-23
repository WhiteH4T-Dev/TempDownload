fdisk -l 
echo ""
read -p "Drive: " DRIVE
(echo m; echo g; echo n; ... ; ... ; echo +550M; echo n; echo 2; ... ; echo +2G; echo t; echo L; echo 1) | fdisk $DRIVE
