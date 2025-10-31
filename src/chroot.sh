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

ROOT_PASSWORD=$(< /bais/.rootpw)
USER_PASSWORD=$(< /bais/.userpw)

echo "root:$ROOT_PASSWORD" | chpasswd

useradd -mG wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

bootctl install

ROOT_PARTUUID=$(blkid --match-tag PARTUUID --output value ${DISK}3)
UCODE_IMAGE=""

if pacman -Q intel-ucode &>/dev/null; then
    UCODE_IMAGE="/intel-ucode.img"
elif pacman -Q amd-ucode &>/dev/null; then
    UCODE_IMAGE="/amd-ucode.img"
fi

cat << BOOT > /boot/loader/entries/arch.conf
title $BOOTLOADER_NAME
linux /vmlinuz-linux
initrd /initramfs-linux.img
initrd $UCODE_IMAGE
options root=PARTUUID=$ROOT_PARTUUID rw quiet splash
BOOT

cat << LOADER > /boot/loader/loader.conf
default arch.conf
timeout $BOOTLOADER_TIMEOUT
editor no
LOADER

for s in "${SYSTEMD_SYSTEM_SERVICES[@]}"; do
    say_green "Enabling system service: $s"
    systemctl enable "$s"
done

for s in "${SYSTEMD_USER_SERVICES[@]}"; do
    say_green "Enabling user service: $s"
    systemctl --user enable "$s"
done

say_green "System configuration complete!"

ask_normal CONFIRM "Would you like to reboot now? (y/N)"

if [[ "$CONFIRM" != [yY] ]]; then
    say_green "You can now exit chroot and reboot into your new system whenever you want."
else
    say_green "Rebooting in..."

    for i in $(seq 3 -1 1); do
        say_green "$i..."
        sleep 1
    done

    shutdown -r now
fi
