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

    # Remove script's temp files.
    rm -rf /mnt/bais/

    swapoff -a || true
    umount -R /mnt || true
}
