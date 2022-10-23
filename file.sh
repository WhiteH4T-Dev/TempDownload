
read -p "AAA: " drive
fdisk $drive << EOF
m
g
n


+550M
n
2

+2G
t
L
1
EOF
