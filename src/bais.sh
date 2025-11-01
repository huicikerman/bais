#! /bin/bash

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/config.sh"

set -euo pipefail

trap cleanup EXIT

[[ ! -d /sys/firmware/efi ]] && die "Reboot your system in UEFI mode to continue."

[[ -z "${DISK:-}" ]] && die "DISK variable is not set!"
[[ ! -b "$DISK" ]] && die "Disk '$DISK' does not exist or is not a block device!"
[[ "$DISK" =~ nvme ]] && echo "Note: Detected NVMe disk, partition naming differs (/dev/nvme0n1pX)."

[[ -z "${EFI_SIZE:-}" ]] && die "EFI_SIZE variable is not set!"
[[ -z "${SWAP_SIZE:-}" ]] && die "SWAP_SIZE variable is not set!"
(( EFI_SIZE < 1 )) && die "EFI_SIZE must be at least 1 GiB!"
(( SWAP_SIZE < 0 )) && die "SWAP_SIZE cannot be negative!"

[[ -z "${USERNAME:-}" ]] && die "USERNAME variable is not set!"
[[ -z "${HOSTNAME:-}" ]] && die "HOSTNAME variable is not set!"

[[ -z "${KEYMAP:-}" ]] && die "KEYMAP variable is not set!"
[[ -z "${LOCALE:-}" ]] && die "LOCALE variable is not set!"
[[ -z "${TIMEZONE:-}" ]] && die "TIMEZONE variable is not set!"
[[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]] && die "Invalid TIMEZONE: $TIMEZONE"

[[ -z "${BOOTLOADER_NAME:-}" ]] && die "BOOTLOADER_NAME variable is not set!"
[[ -z "${BOOTLOADER_TIMEOUT:-}" ]] && die "BOOTLOADER_TIMEOUT variable is not set!"
(( BOOTLOADER_TIMEOUT < 0 )) && die "BOOTLOADER_TIMEOUT cannot be negative!"

[[ ${#SYSTEMD_SYSTEM_SERVICES[@]} -eq 0 ]] && die "SYSTEMD_SYSTEM_SERVICES is empty!"
[[ ${#SYSTEMD_USER_SERVICES[@]} -eq 0 ]] && die "SYSTEMD_USER_SERVICES is empty!"
[[ ${#BASIC_PACKAGES[@]} -eq 0 ]] && die "BASIC_PACKAGES is empty!"

mount | grep -q "$DISK" && die "'$DISK' is currently mounted! Unmount to continue."

loadkeys "$KEYMAP"
timedatectl set-ntp true

ask_normal CONFIRM "The disk '$DISK' will be cleared before partitioning. \
This can NOT be undone. Are you sure you want to continue? (y/N):"

if [[ "$CONFIRM" != [yY] ]]; then
    die "Script aborted by the user."
else
    say_yellow "Clearing the disk in..."

    for i in $(seq 5 -1 1); do
        say_yellow "$i..."
        sleep 1
    done

    sgdisk --zap-all "$DISK"
fi

say_green "Partitioning '$DISK'..."

# References for partition GUIDs and table layouts:
#
# https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
# https://wiki.archlinux.org/title/Partitioning#Example_layouts

if [[ "$SWAP_SIZE" -eq 0 ]]; then
    parted --script --align optimal "$DISK" \
        mklabel gpt \
        mkpart EFI fat32 0% ${EFI_SIZE}GiB \
        mkpart ROOT ext4 ${EFI_SIZE}GiB 100% \
        type 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
        type 2 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
else
    SWAP_END=$((EFI_SIZE + SWAP_SIZE + 1))

    parted --script --align optimal "$DISK" \
        mklabel gpt \
        mkpart EFI fat32 0% ${EFI_SIZE}GiB \
        mkpart SWAP linux-swap ${EFI_SIZE}GiB ${SWAP_END}GiB \
        mkpart ROOT ext4 ${SWAP_END}GiB 100% \
        type 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
        type 2 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F \
        type 3 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
fi

say_green "Formatting partitions..."
mkfs.ext4 -F -L ROOT "${DISK}3"
mkfs.fat -F 32 -n EFI "${DISK}1"
mkswap -L SWAP "${DISK}2"

say_green "Mounting partitions..."
mount "${DISK}3" /mnt
mount --mkdir "${DISK}1" /mnt/boot
swapon "${DISK}2"

say_green "Installing basic packages..."
pacstrap -K /mnt "${BASIC_PACKAGES[@]}"

say_green "Generating fstab..."
genfstab -t PARTUUID /mnt >> /mnt/etc/fstab

say_green "Setting passwords for your system..."

ROOT_PASS_FILE=$(mktemp)
USER_PASS_FILE=$(mktemp)

while true; do
    ask_secret ROOT_PASSWORD "Enter root password:"
    ask_secret ROOT_CONFIRM "Confirm root password:"

    [[ "$ROOT_PASSWORD" != "$ROOT_CONFIRM" ]] && say_red "Passwords do not match. Try again." || break
done

while true; do
    ask_secret USER_PASSWORD "Enter password for user '$USERNAME':"
    ask_secret USER_CONFIRM "Confirm password for user '$USERNAME':"

    [[ "$USER_PASSWORD" != "$USER_CONFIRM" ]] && say_red "Passwords do not match. Try again." || break
done

echo "$ROOT_PASSWORD" > "$ROOT_PASS_FILE"
echo "$USER_PASSWORD" > "$USER_PASS_FILE"

mkdir /mnt/bais

cp "$(dirname "$0")/chroot.sh" /mnt/bais/
cp "$(dirname "$0")/config.sh" /mnt/bais/
cp "$(dirname "$0")/utils.sh" /mnt/bais/

cp "$ROOT_PASS_FILE" /mnt/bais/.root-pw
cp "$USER_PASS_FILE" /mnt/bais/.user-pw

say_green "Base setup complete!"

ask_normal CONFIRM "Would you like to chroot and finalize installation now? (y/N):"

if [[ "$CONFIRM" == [yY] ]]; then
    arch-chroot /mnt /bais/chroot.sh
else
    say_green "You can later chroot manually with: arch-chroot /mnt /bais/chroot.sh"
fi
