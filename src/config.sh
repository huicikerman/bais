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
BOOTLOADER_TIMEOUT=10

SYSTEMD_SYSTEM_SERVICES=(
    iwd.service
    sshd.service
    dhcpcd.service
    systemd-timesyncd.service
    systemd-boot-update.service
    reflector.service
    reflector.timer
)

SYSTEMD_USER_SERVICES=(
    pipewire.service
    wireplumber.service
)

BASIC_PACKAGES=(
    # System:
    base
    base-devel
    linux
    linux-firmware
    linux-firmware-intel
    intel-ucode

    # Basics:
    git
    nano
    openssh
    sudo

    # Networking:
    iwd
    dhcpcd

    # Audio:
    pipewire
    pipewire-alsa
    pipewire-audio
    pipewire-pulse
    pipewire-jack
    wireplumber

    # X11:
    xorg-xinit
    xorg-server
    xorg-apps

    # Fonts:
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra

    # Manuals:
    man-db
    man-pages
    man-pages-es

    # Misc:
    fastfetch
    reflector
    xdg-user-dirs
)
