DISK="/dev/sda"

# The following values are in GiB.
# You can set SWAP_SIZE to 0 to disable the swap partition altogether.
EFI_SIZE=1
SWAP_SIZE=4

USERNAME="user"
HOSTNAME="arch"

KEYMAP="us"
LOCALE="en_US.UTF-8"
TIMEZONE="Europe/Madrid"

BOOTLOADER_NAME="Arch Linux"
BOOTLOADER_TIMEOUT=5

BASIC_PACKAGES=(
    # Basic
    base
    base-devel
    linux
    linux-firmware
    linux-firmware-intel
    sof-firmware
    intel-ucode
    iwd

    # Audio
    pipewire
    pipewire-alsa
    pipewire-audio
    pipewire-pulse
    pipewire-jack
    wireplumber

    # X.Org
    xorg-xinit
    xorg-server
    xorg-apps

    # Misc
    git
    micro
    openssh
    reflector
    sudo
    xdg-user-dirs
    man-db
    man-pages
    man-pages-es
)
