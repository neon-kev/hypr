#!/usr/bin/env bash

# --- 1. INITIAL SETUP ---
timedatectl set-ntp true
pacman -Sy --needed --noconfirm archlinux-keyring f2fs-tools gptfdisk

# --- 2. DRIVE SELECTION & AUTOMATED PARTITIONING ---
clear
lsblk
echo "Enter the drive (e.g., /dev/sda or /dev/nvme0n1):"
read -r drive
echo "DANGER: This will WIPE $drive. Proceed? [y/N]"
read -r confirm
[[ "$confirm" != "y" ]] && exit 1

# Split into 2: 512MB EFI, and the REST for everything else (Fluid)
sgdisk --zap-all "$drive"
sgdisk --new=1:0:+512M --typecode=1:ef00 --change-name=1:"EFI" "$drive"
sgdisk --new=2:0:0     --typecode=2:8304 --change-name=2:"ROOT" "$drive"
partprobe "$drive"
sleep 2

# Identify partition paths
if [[ "$drive" == *"nvme"* ]]; then
    boot_p="${drive}p1"; root_p="${drive}p2"
else
    boot_p="${drive}1"; root_p="${drive}2"
fi

# --- 3. FORMATTING & MOUNTING (F2FS) ---
mkfs.fat -F 32 "$boot_p"
# Using F2FS for the single large "Fluid" partition
mkfs.f2fs -O extra_attr,inode_checksum,sb_checksum "$root_p"

mount -o noatime,discard "$root_p" /mnt
mkdir -p /mnt/boot
mount "$boot_p" /mnt/boot

# --- 4. BASE INSTALLATION ---
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware f2fs-tools intel-ucode git nano sddm networkmanager sudo
genfstab -U /mnt >> /mnt/etc/fstab

# Capture PARTUUID (Fixed the variable loss bug)
export MY_PARTUUID=$(blkid -s PARTUUID -o value "$root_p")

# --- 5. CREATE POST-INSTALL CHROOT SCRIPT ---
cat <<CHROOT_EOF > /mnt/post_install.sh
#!/bin/bash
ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-linux" > /etc/hostname

# F2FS Kernel Module Support (Critical for booting)
sed -i 's/^MODULES=(/MODULES=(f2fs /' /etc/mkinitcpio.conf
mkinitcpio -P

# Bootloader (Systemd-boot)
bootctl install
cat <<EOF > /boot/loader/entries/Arch-Zen.conf
title Arch Linux (Zen-F2FS)
linux /vmlinuz-linux-zen
initrd /intel-ucode.img
initrd /initramfs-linux-zen.img
options root=PARTUUID=$MY_PARTUUID rw quiet splash loglevel=3
EOF
echo "default Arch-Zen" > /boot/loader/loader.conf

# Users & Groups
echo "Enter root password:"
passwd
echo "Enter your username:"
read username
useradd -m -G wheel,audio,video -s /bin/bash "\$username"
echo "Enter password for \$username:"
passwd "\$username"
echo "\$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/\$username

# Services
systemctl enable sddm
systemctl enable NetworkManager

# --- 6. AUR & HYPRLAND ---
sudo -u "\$username" bash <<AUR_EOF
cd /home/\$username
git clone https://aur.archlinux.org
cd paru && makepkg -si --noconfirm
cd .. && rm -rf paru
# Installs core apps from your original list
paru -S --needed --noconfirm floorp-bin vscodium-bin hyprland-git waybar-git foot fastfetch
AUR_EOF
CHROOT_EOF

# --- 7. EXECUTION ---
chmod +x /mnt/post_install.sh
arch-chroot /mnt ./post_install.sh
rm /mnt/post_install.sh
umount -R /mnt
echo "Fluid F2FS installation complete! Rebooting..."
sleep 5
reboot
