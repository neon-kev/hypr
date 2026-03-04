#!/usr/bin/env bash
echo -ne "
__________________________________________________________________________________________________________
|                                                                                                         |
|                                  ███    ███  █████   ██████  ██  ██████                                 |
|                                  ████  ████ ██   ██ ██       ██ ██                                      |
|                                  ██ ████ ██ ███████ ██   ███ ██ ██                                      |
|                                  ██  ██  ██ ██   ██ ██    ██ ██ ██                                      |
|                                  ██      ██ ██   ██  ██████  ██  ██████                                 |
|                                                                                                         |
| █████  ██████   ██████ ██   ██     ██ ███    ██ ███████ ████████  █████  ██      ██      ███████ ██████ |
|██   ██ ██   ██ ██      ██   ██     ██ ████   ██ ██         ██    ██   ██ ██      ██      ██      ██   ██|
|███████ ██████  ██      ███████     ██ ██ ██  ██ ███████    ██    ███████ ██      ██      █████   ██████ |
|██   ██ ██   ██ ██      ██   ██     ██ ██  ██ ██      ██    ██    ██   ██ ██      ██      ██      ██   ██|
|██   ██ ██   ██  ██████ ██   ██     ██ ██   ████ ███████    ██    ██   ██ ███████ ███████ ███████ ██   ██|
|                                                                                                         |
|---------------------------------------------------------------------------------------------------------|
|                Install arch linux in few clicks. Even a 5 year kid can install arch now.                |
|---------------------------------------------------------------------------------------------------------|
|                               Base Installation Of Arch Linux Begins Now                                |
| Check: https://github.com/whoisYoges/magic-arch-installer/ To Know More Details About This Installation |
|---------------------------------------------------------------------------------------------------------|
|_________________________________________________________________________________________________________|

"
sleep 3s
echo "Internet Connection is a must to begin."
echo "Updating Keyrings"
sleep 2s
pacman -Sy --needed --noconfirm archlinux-keyring
clear
echo "Ensuring if the system clock is accurate."
timedatectl set-ntp true
sleep 3s
clear

lsblk
echo "Enter the drive to install arch linux on it. (/dev/...)"
echo "Enter Drive (eg. /dev/sda or /dev/vda or /dev/nvme0n1 or something similar)"
read drive
sleep 2s
clear

echo "Create partitions:"
echo "1) EFI 512MB --dev/sda1"
echo "2) Root 238G --dev/sda2"

lsblk
echo "Choose a familier disk utility tool to partition your drive!"
echo " 1. fdisk"
echo " 2. cfdisk"
echo " 3. gdisk"
echo " 4. parted"
read partitionutility

case "$partitionutility" in
  1 | fdisk | Fdisk | FDISK)
  partitionutility="fdisk"
  ;;
  2 | cfdisk | Cfdisk | CFDISK)
  partitionutility="cfdisk"
  ;;
  3 | gdisk | Gdisk | GDISK)
  partitionutility="gdisk"
  ;;
  4 | parted | Parted | PARTED)
  partitionutility="parted"
  ;;
  *)
  echo "Unknown or unsupported disk utility! Default = cfdisk."
  partitionutility="cfdisk"
  ;;
esac
echo ""$partitionutility" is the selected disk utility tool for partition."
sleep 3s
clear
echo "Getting ready for creating partitions!"
echo "root and boot partitions are mandatory."
echo "home and swap partitions are optional but recommended!"
echo "Also, you can create a separate partition for timeshift backup (optional)!"
echo "Getting ready in 9 seconds"
sleep 9s
"$partitionutility" "$drive"
clear
lsblk
echo "choose your linux file system type for formatting drives"
echo " 1. ext4"
echo " 2. xfs"
echo " 3. btrfs"
echo " 4. f2fs"
echo " Boot partition will be formatted in fat32 file system type."
read filesystemtype

case "$filesystemtype" in
  1 | ext4 | Ext4 | EXT4)
  filesystemtype="ext4"
  ;;
  2 | xfs | Xfs | XFS)
  filesystemtype="xfs"
  ;;
  3 | btrfs | Btrfs | BTRFS)
  filesystemtype="btrfs"
  ;;
  4 | f2fs | F2fs | F2FS)
  filesystemtype="f2fs"
  ;;
  *)
  echo "Unknown or unsupported Filesystem. Default = ext4."
  filesystemtype="ext4"
  ;;
esac
echo ""$filesystemtype" is the selected file system type."
sleep 3s
clear
echo "Getting ready for formatting drives."
sleep 3s
lsblk
echo "Enter the root partition (eg: /dev/sda1): "
read rootpartition
mkfs."$filesystemtype" "$rootpartition"
mount "$rootpartition" /mnt
clear
lsblk
read -p "Did you also create separate home partition? [y/n]: " answerhome
case "$answerhome" in
  y | Y | yes | Yes | YES)
  echo "Enter home partition (eg: /dev/sda2): "
  read homepartition
  mkfs."$filesystemtype" "$homepartition"
  mkdir /mnt/home
  mount "$homepartition" /mnt/home
  ;;
  *)
  echo "Skipping home partition!"
  ;;
esac
clear
lsblk
read -p "Did you also create swap partition? [y/n]: " answerswap
case "$answerswap" in
  y | Y | yes | Yes | YES)
  echo "Enter swap partition (eg: /dev/sda3): "
  read swappartition
  mkswap "$swappartition"
  swapon "$swappartition"
  ;;
  *)
  echo "Skipping Swap partition!"
  ;;
esac

clear
lsblk
read -p "Enter the boot partition. (eg. /dev/sda4): " answerefi
mkfs.fat -F 32 "$answerefi"
mkdir -p /mnt/boot
mount "$answerefi" /mnt/boot
clear
lsblk
sleep 3s
clear
clear
#Replace kernel and kernel-header file and with your requirements (eg linux-zen linux-zen-headers or linux linux-headers)
#Include intel-ucode/amd-ucode if you use intel/amd processor.
MY_PARTUUID=$(blkid -s PARTUUID -o value "$rootpartition")
echo "Installing Base system with lts kernel!!!"
sleep 2s
pacstrap /mnt base base-devel linux-zen linux-zen-headers intel-ucode nano linux-firmware git inotify-tools wireplumber reflector man sudo sddm
clear
echo "generating fstab file"
genfstab -U /mnt >> /mnt/etc/fstab
sleep 2s
clear
sed '1,/^#part2$/d' uefi-base-install.sh > /mnt/post_base-install.sh
chmod +x /mnt/post_base-install.sh
arch-chroot /mnt ./post_base-install.sh
clear
echo "unmounting all the drives"
umount -R /mnt
sleep 2s
clear
echo -ne "
__________________________________________________________________________________________________________
|                                            THANKS FOR USING                                             |
|---------------------------------------------------------------------------------------------------------|
|                                  ███    ███  █████   ██████  ██  ██████                                 |
|                                  ████  ████ ██   ██ ██       ██ ██                                      |
|                                  ██ ████ ██ ███████ ██   ███ ██ ██                                      |
|                                  ██  ██  ██ ██   ██ ██    ██ ██ ██                                      |
|                                  ██      ██ ██   ██  ██████  ██  ██████                                 |
|                                                                                                         |
| █████  ██████   ██████ ██   ██     ██ ███    ██ ███████ ████████  █████  ██      ██      ███████ ██████ |
|██   ██ ██   ██ ██      ██   ██     ██ ████   ██ ██         ██    ██   ██ ██      ██      ██      ██   ██|
|███████ ██████  ██      ███████     ██ ██ ██  ██ ███████    ██    ███████ ██      ██      █████   ██████ |
|██   ██ ██   ██ ██      ██   ██     ██ ██  ██ ██      ██    ██    ██   ██ ██      ██      ██      ██   ██|
|██   ██ ██   ██  ██████ ██   ██     ██ ██   ████ ███████    ██    ██   ██ ███████ ███████ ███████ ██   ██|
|                                                                                                         |
|---------------------------------------------------------------------------------------------------------|
|                Install arch linux in few clicks. Even a 5 year kid can install arch now.                |
|---------------------------------------------------------------------------------------------------------|
|                          Base Installation Of Arch Linux Is Completed Now                               |
|Check: https://github.com/whoisYoges/magic-arch-installer for Graphical User Interface (GUI) Installation|
|---------------------------------------------------------------------------------------------------------|
|_________________________________________________________________________________________________________|
"
echo "Base Installation Finished. REBOOTING IN 10 SECONDS!!!"
sleep 10s
reboot

#part2
clear
echo "Working inside new root system!!!"
echo "setting timezone"
#Replace Asia/Kathmandu with your timezone
ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc
sleep 2s
clear
echo "generating locale"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
sleep 2s
clear
echo "setting LANG variable"
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sleep 2s
clear
echo "setting console keyboard layout"
echo "KEYMAP=us" > /etc/vconsole.conf
sleep 2s
clear
echo "Set up your hostname!"
echo "Enter your computer name: "
read hostname
echo $hostname > /etc/hostname
echo "Checking hostname (/etc/hostname)"
cat /etc/hostname
sleep 3s
clear
echo "setting up hosts file"
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname" >> /etc/hosts
clear
echo "checking /etc/hosts file"
cat /etc/hosts
sleep 3s
clear
#if you are dualbooting, add os-prober with grub and efibootmgr
echo "Installing grub efibootmgr and networkmanager"
sleep 2s



pacman -Sy --needed --noconfirm  efibootmgr networkmanager
clear


lsblk
echo "Enter the boot partition to install bootloader. (eg: /dev/sda4): "
read efipartition
efidirectory="/boot"
if [ ! -d "$efidirectory" ]; then
  mkdir -p "$efidirectory"
fi
mount "$efipartition" "$efidirectory"
clear
lsblk
sleep 2s
echo "Installing systemd bootloader in /boot/ parttiton"

bootctl install --path=/boot

if [ -z "$MY_PARTUUID" ]; then
    echo "Error: Could not find PARTUUID for /dev/sda2. Check your partition table!"
else

cat <<EOF > /boot/loader/entries/Arch-Zen.conf
title   Arch-Zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=PARTUUID=$MY_PARTUUID rw quiet splash loglevel=3
EOF
    echo "Success: Arch-Zen.conf created with PARTUUID $MY_PARTUUID"
fi

cat <<EOF > /boot/loader/loader.conf
timeout 0
#console-mode keep
default Arch-Zen
editor no
EOF

sleep 2s

clear
echo "Enabling NetworkManager"
systemctl enable NetworkManager
sleep 2s
clear
echo "Enter password for root user:"
passwd
clear
echo "Adding regular user!"
echo "Enter username to add a regular user: "
read username
useradd -m -g users -G wheel,audio,video -s /bin/bash $username
echo "Enter password for "$username": "
passwd $username
clear
echo "NOTE: ALWAYS REMEMBER THIS USERNAME AND PASSWORD YOU PUT JUST NOW."
sleep 3s
#Adding sudo previliages to the user you created
echo "Giving sudo access to "$username"!"

cat <<EOF > /etc/sudoers.d/$username
$username ALL=(root) NOPASSWD: /usr/bin/wg, /usr/bin/wg-quick
$username ALL=(root) NOPASSWD: /etc/wireguard/
$username ALL=(ALL) NOPASSWD: /usr/bin/hyprlock
$username ALL=(ALL) NOPASSWD: /usr/bin/hypridle
$username ALL=(root) NOPASSWD: /home/$username/.config/hypr/scripts/updates-handler.sh
EOF

clear
su - $username
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

PACMAN_APPS=(
    "ark" "base-devel" "brightnessctl" "dunst" "efibootmgr" "git" "foot"
    "fastfetch" "gnome-system-monitor" "gwenview" "haruna" "inotify-tools"
    "kdeconnect" "libreoffice-fresh" "linux-firmware" "linux-zen-headers"
    "okular" "pacman-contrib" "pipewire" "pipewire-alsa" "pipewire-jack"
    "pipewire-pulse" "plymouth" "reflector" "rofi" "sddm" "swww"
    "ttf-jetbrains-mono-nerd" "ttf-twemoji" "typescript" "wget"
    "wireguard-tools" "xdg-desktop-portal-hyprland"
)

# 2. Hyprland Ecosystem (-git versions via AUR)
# Verified names on AUR for the latest git builds
HYPR_GIT_APPS=(
    "hyprland-git" "aquamarine-git" "hyprutils-git" "hyprwayland-scanner-git"
    "hyprgraphics-git" "hypridle-git" "hyprlock-git" "hyprsunset-git"
    "hyprpicker-git" "hyprcursor-git" "hyprpaper-git" "hyprshot-git"
    "hyprpolkitagent-git" "hyprland-qt-support-git" "hyprqt6engine-git"
    "waybar-git" "wlogout" "wallust" "waypaper" "hyprpicker-git" "seatd-git"
)


# 3. Third-Party / Binary Apps (AUR)
USER_APPS=(
    "floorp-bin" "ungoogled-chromium-bin" "vscodium-bin"
    "clipvault" "powerdevil"
)

echo "--- Starting Installation ---"

# Install Pacman Apps
echo "Installing System Apps via Pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_APPS[@]}"

# Install Hypr-Git and User Apps
echo "Installing Hyprland-Git and User Apps via Yay..."
paru -S --needed --noconfirm "${HYPR_GIT_APPS[@]}" "${USER_APPS[@]}"

echo "--- Installation Complete ---"
usermod -aG seat,video $username
systemctl enable seatd
systemctl enable --now seatd.service
clear
rm /post_base-install.sh
exit
