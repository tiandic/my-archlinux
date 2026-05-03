#!/bin/bash
set -euo pipefail

DISK="$1"

if [[ ! -b "$DISK" ]] ; then
    echo "Usage: $0 <disk path>"
    exit 1
fi

# 创建分区
sgdisk --zap-all "$DISK"
sgdisk -n "1:0:+512M" -t "1:ef00" -c "1:EFI" "$DISK"
sgdisk -n "2:0:+2G" -t "2:8300" -c "2:boot" "$DISK"
sgdisk -n "3:0:0" -t "3:8309" -c "3:luks" "$DISK"
partprobe "$DISK"

if [[ "$DISK" == *nvme* ]] ; then
    EFI_PART="${DISK}p1"
    BOOT_PART="${DISK}p2"
    LUKS_PART="${DISK}p3"
else
    EFI_PART="${DISK}1"
    BOOT_PART="${DISK}2"
    LUKS_PART="${DISK}3"
fi


# 格式化加密分区并设置密码
cryptsetup luksFormat "$LUKS_PART"
cryptsetup open "$LUKS_PART" cryptroot

# 格式化分区
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 "$BOOT_PART"
mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@{,home,var,tmp,snapshots,swap}
umount /mnt

# 挂载分区
mount -o subvol=@,compress=zstd,noatime,space_cache=v2,discard=async /dev/mapper/cryptroot /mnt

mkdir -p /mnt/{home,var,snapshots,tmp,swap,boot/efi}

mount --mkdir "$BOOT_PART" /mnt/boot
mount --mkdir "$EFI_PART" /mnt/boot/efi

mount -o subvol=@home,compress=zstd,space_cache=v2,discard=async /dev/mapper/cryptroot /mnt/home
mount -o subvol=@var,compress=zstd,noatime,space_cache=v2,discard=async /dev/mapper/cryptroot /mnt/var
mount -o subvol=@snapshots,noatime,space_cache=v2 /dev/mapper/cryptroot /mnt/snapshots
mount -o subvol=@tmp,noatime,space_cache=v2 /dev/mapper/cryptroot /mnt/tmp
mount -o subvol=@swap,noatime,space_cache=v2 /dev/mapper/cryptroot /mnt/swap

chattr +C /mnt/var/log
chattr +C /mnt/var/cache
chattr +C /mnt/var/tmp

# 安装系统
pacstrap -K /mnt base linux linux-firmware networkmanager vim tmux grub efibootmgr btrfs-progs

genfstab -U /mnt >> /mnt/etc/fstab

LUKS_UUID=$(blkid -s UUID -o value "$LUKS_PART")

# root 密码
while true ; do
    read -rsp "Set root password: " PASSWORD
    echo
    read -rsp "Enter password again: " PASSWORD2
    echo

    if [[ "$PASSWORD" == "$PASSWORD2" ]] ; then
        break
    fi
    echo "The passwords entered twice do not match!"
done

echo "root:${PASSWORD}" | arch-chroot /mnt chpasswd

arch-chroot /mnt /bin/bash << EOF
# 时间
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

# 本地化
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 网络
systemctl enable NetworkManager

# initramfs
sed -i 's/^HOOKS=(.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/'  /etc/mkinitcpio.conf
mkinitcpio -P

# grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch
sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"rd.luks.name=${LUKS_UUID}=cryptroot root=\/dev\/mapper\/cryptroot\"/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

EOF

