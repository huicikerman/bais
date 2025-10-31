#! /bin/bash

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/config.sh"

set -euo pipefail

grep -qxF "$LOCALE UTF-8" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

echo "$HOSTNAME" > /etc/hostname
cat << HOSTS > /etc/hosts
::1 localhost
127.0.0.1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS

ROOT_PASSWORD=$(< /root/.rootpw)
USER_PASSWORD=$(< /root/.userpw)

rm -f /root/.rootpw /root/.userpw

echo "root:$ROOT_PASSWORD" | chpasswd

useradd -mG wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable iwd
systemctl enable sshd
systemctl enable systemd-timesyncd

bootctl --esp-path=/boot/efi install

ROOT_PARTUUID=$(blkid --match-tag PARTUUID --output value ${DISK}3)
UCODE_IMAGE=""

if pacman -Q intel-ucode &>/dev/null; then
    UCODE_IMAGE="/intel-ucode.img"
elif pacman -Q amd-ucode &>/dev/null; then
    UCODE_IMAGE="/amd-ucode.img"
fi

cat << BOOT > /boot/efi/loader/entries/arch.conf
title $BOOTLOADER_NAME
linux /vmlinuz-linux
initrd /initramfs-linux.img
initrd $UCODE_IMAGE
options root=PARTUUID=$ROOT_PARTUUID rw quiet splash
BOOT

cat << LOADER > /boot/efi/loader/loader.conf
default arch.conf
timeout $BOOTLOADER_TIMEOUT
editor no
LOADER

say "System configuration complete!"
say "You can now exit chroot and reboot into your new system."
