say_red () { echo -e "\e[1;31m[BAIS] $1\e[0m"; }
say_green () { echo -e "\e[1;32m[BAIS] $1\e[0m"; }
say_yellow () { echo -e "\e[1;33m[BAIS] $1\e[0m"; }

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

    [[ -f /mnt/bais/.reboot-flag ]] && REBOOT=true || REBOOT=false

    swapoff -a || true

    if mountpoint -q /mnt; then
        umount -R /mnt || say_yellow "Some mount points could not be unmounted cleanly."
    fi

    rm -rf /mnt/bais/ || true

    if [[ "$REBOOT" = true ]]; then
        say_yellow "Reboot flag detected, rebooting in..."

        for i in $(seq 3 -1 1); do
            say_yellow "$i..."
            sleep 1
        done

        reboot || systemctl reboot || shutdown -r now
    else
        say_green "Cleanup complete. You can reboot manually when ready."
    fi
}
