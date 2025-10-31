say () {
    echo -e "\e[1;32m[BAIS] $1\e[0m"
}

ask_normal () {
    say "$2"
    read $1
}

ask_secret () {
    say "$2"
    read -s $1
}

die () {
    say "\e[1;31m$1\e[0m"
    exit 1
}

cleanup () {
    say "Cleaning up before exiting..."

    # Remove script's temp files.
    rm -rf /mnt/bais/

    swapoff -a || true
    umount -R /mnt || true
}
