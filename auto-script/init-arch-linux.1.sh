#!/bin/bash
set -euo pipefail

# 普通用户
read -p "user name: " user_name

while true ; do
    read -rsp "set user password: " user_passwd
    echo
    read -rsp "Enter password again: " user_passwd2
    echo

    if [[ "$user_passwd" == "$user_passwd2" ]] ; then
        break
    fi
    echo "The passwords entered twice do not match!"
done

pacman -S --noconfirm --needed sudo vi

useradd -mG wheel "$user_name"
echo "${user_name}:${user_passwd}" | chpasswd

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 开启32位源,添加archlinuxcn源
sed -ie '{N;s/#\(\[multilib\]\n\)#\(Include.*\)/\1\2/}' /etc/pacman.conf
printf '[archlinuxcn]\nServer = https://repo.archlinuxcn.org/$arch\n' >> /etc/pacman.conf
pacman -Syu --noconfirm --needed archlinuxcn-keyring 

# 安装AUR助手,字体,音视频,性能模式
pacman -S --noconfirm --needed base-devel yay noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd sof-firmware alsa-ucm-conf pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack

machinectl shell "${user_name}@.host" << EOF
systemctl --user enable --now pipewire pipewire-pulse wireplumber
EOF

pacman -S --noconfirm --needed power-profiles-daemon bluez
systemctl enable --now power-profiles-daemon bluetooth

# swap
btrfs filesystem mkswapfile --size 16g --uuid clear /swap/swapfile
swapon /swap/swapfile

echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

# 显卡
cpu_info=$(grep "model name" /proc/cpuinfo | head -1)
if [[ "$cpu_info" == *"Intel"* ]] ; then
    pacman -S --noconfirm --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel
else
    pacman -S --noconfirm --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
fi

# 快照
pacman -S --noconfirm --needed snapper btrfs-assistant grub-btrfs inotify-tools snap-pac
echo "Please manually restart, then run init-arch-linux.2.sh"
