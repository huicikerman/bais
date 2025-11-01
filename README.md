# bAIS - basic Arch Install Script

Welcome to **bAIS**, _yet another_ custom Arch Linux installation script!

I made this to simplify repetitive setup process that follows every fresh Arch Linux install.
Unlike [Archinstall](https://wiki.archlinux.org/title/Archinstall), **bAIS** is much, much simpler.
It's designed to be a starting point which you can freely modify however you like to match your own
preferences or workflow.

## Configuration

All configuration is done through the `config.sh` file. You should review and adjust the variables
to fit your setup before running the script.

This script does **NOT** install any DE or WM, it just configures a basic system and reboots to a
fresh Arch Linux install. You can make it to install the necessary packages in `config.sh` but any
other external configuration must be done either manually or by implementing it in `bais.sh` or
`chroot.sh` yourself.

> [!WARNING]
> If you are using an NVMe disk make sure to append the partition's "_p_" when referencing it in
> **$DISK** inside `config.sh` (_i.e._ DISK="/dev/nvme0n1**p**")

## Usage

1. Boot into the official Arch Linux installation medium.
2. Ensure you have internet connection (`ping -c 2 8.8.8.8`).
3. Download and extract the **bAIS** repository.
4. Run the `bais.sh` script file.

Simply put, run:

``` bash
curl -LO https://github.com/huicikerman/bais/archive/main.zip
bsdtar -xvf main.zip

cd bais-main/src/
chmod +x *

./bais.sh
```
