say_green () {
    echo -e "\e[1;32m[BAIS] $1\e[0m"
}

say_red () {
    echo -e "\e[1;31m[BAIS] $1\e[0m"
}

ask_normal () {
    say_green "$2"
    read $1
}

ask_secret () {
    say_green "$2"
    read -s $1
}

die () {
    say_red "$1"
    exit 1
}

cleanup () {
    say_green "Cleaning up before exiting..."

    swapoff -a || true

    if mountpoint -q /mnt; then
        umount -R /mnt || say_yellow "Some mount points could not be unmounted cleanly."
    fi

    if [[ -f /mnt/bais/.reboot-flag ]]; then
        rm -rf /mnt/bais/ || true

        say_green "Reboot flag detected, rebooting now..."
        shutdown -r now
    else
        rm -rf /mnt/bais/ || true

        say_green "Cleanup complete. You can reboot manually when ready."
    fi
}

