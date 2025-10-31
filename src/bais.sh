#! /bin/bash

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/config.sh"

set -euo pipefail

trap cleanup EXIT

[ ! -d /sys/firmware/efi ] && die "Reboot your system in UEFI mode to continue."
[[ -z "${DISK:-}" ]] && die "DISK variable not set!"
[[ ${#BASIC_PACKAGES[@]} -eq 0 ]] && die "BASIC_PACKAGES is empty!"

loadkeys "$KEYMAP"
timedatectl set-ntp true

ask_normal "The disk $DISK will be cleared before partitioning. This cannot be undone. Confirm? (y/N): " CONFIRM

if [[ "$CONFIRM" != [yY] ]]; then
    die "Script aborted by the user."
else
    say "Clearing the disk in..."

    for i in $(seq 5 -1 0); do
        say "$i..."
        sleep 1
    done

    sgdisk --zap-all "$DISK"
fi

say "Partitioning '$DISK'..."

# References for partition GUIDs and table layouts:
#
# https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
# https://wiki.archlinux.org/title/Partitioning#Example_layouts

if [[ "$SWAP_SIZE" -eq 0 ]]; then
    parted --script --align optimal "$DISK" \
        mklabel gpt \
        mkpart EFI C12A7328-F81F-11D2-BA4B-00A0C93EC93B 0% ${EFI_SIZE}GiB \
        mkpart ROOT 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 ${EFI_SIZE}GiB 100%
else
    SWAP_END=$((EFI_SIZE + SWAP_SIZE + 1))

    parted --script --align optimal "$DISK" \
        mklabel gpt \
        mkpart EFI C12A7328-F81F-11D2-BA4B-00A0C93EC93B 0% ${EFI_SIZE}GiB \
        mkpart SWAP 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F ${EFI_SIZE}GiB ${SWAP_END}GiB \
        mkpart ROOT 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 ${SWAP_END}GiB 100%
fi

say "Formatting partitions..."
mkfs.fat -F32 -n EFI "${DISK}1"
mkswap -L SWAP "${DISK}2"
mkfs.ext4 -L ROOT "${DISK}3"

say "Mounting partitions..."
mount "${DISK}3" /mnt
mount --mkdir "${DISK}1" /mnt/boot/efi
swapon "${DISK}2"

say "Installing basic packages..."
pacstrap -K /mnt "${BASIC_PACKAGES[@]}"

say "Generating fstab..."
genfstab -t PARTUUID /mnt >> /mnt/etc/fstab

say "Setting passwords for your system..."

ROOT_PASS_FILE=$(mktemp)
USER_PASS_FILE=$(mktemp)

while true; do
    ask_secret "Enter root password: " ROOT_PASSWORD
    ask_secret "Confirm root password: " ROOT_CONFIRM

    [[ "$ROOT_PASSWORD" != "$ROOT_CONFIRM" ]] && say "Passwords do not match. Try again." || break
done

while true; do
    ask_secret "Enter password for user '$USERNAME': " USER_PASSWORD
    ask_secret "Confirm password for user '$USERNAME': " USER_CONFIRM

    [[ "$USER_PASSWORD" != "$USER_CONFIRM" ]] && say "Passwords do not match. Try again." || break
done

echo "$ROOT_PASSWORD" > "$ROOT_PASS_FILE"
echo "$USER_PASSWORD" > "$USER_PASS_FILE"

cp "$(dirname "$0")/chroot.sh" /mnt/root/
cp "$(dirname "$0")/config.sh" /mnt/root/
cp "$(dirname "$0")/utils.sh" /mnt/root/

cp "$ROOT_PASS_FILE" /mnt/root/.rootpw
cp "$USER_PASS_FILE" /mnt/root/.userpw

say "Base setup complete!"

ask_normal "Do you want to chroot and finalize installation now? (y/N): " CONFIRM

if [[ "$CONFIRM" == [yY] ]]; then
    arch-chroot /mnt /root/chroot.sh
else
    say "You can later chroot manually with: arch-chroot /mnt /root/chroot.sh"
fi
