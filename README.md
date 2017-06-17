# Ubuntu LUKS auto unlock

## Do not miss information
This is part of educational materials about Ubuntu administration from my site
[http://gasparchilingarov.com/](http://gasparchilingarov.com). 

Click link and subscibe to mailing list to start learning today.

## Purpose

This script is intended to help unlocking Ubuntu system encrypted disks
automatically when it is used in known environment (at home). In all other
environments it will still ask for passwords to unlock disks.

This setup intends to protect system **only from accidental laptop theft**. If you are
potential hacking target - do not use it, your data may be at risk.

Right now scripts take into account:
 * MAC address of your Wifi network
 * information from your external display

If you use it without external monitor (it will pick up your build-in monitor
information) there is a risk someone can guess/scan your Wifi and find out
MAC address and be able to generate correct decryption key, so do not use it.

## Compatibility

Scripts are tested on Ubuntu 16.04 64-bit only. Use it on your own risk on other systems.


## Usage

Copy files from repository to corresponding directories on your Ubuntu system.

Run `/usr/local/bin/autounlock_install_dependency.sh` to install necessary
dependencies.

Configure your Wifi interface (most probably "wlan0"), Wifi network name and
LUKS partition key slot number in `/usr/local/etc/auto_unlock.conf`.

You can run `cryptsetup luksDump /dev/sdXXXX` to check which slots are free on
your encrypted partitions. LUKS partition can have up to 8 keys for
decyphering. Key slot `0` is used by default for your manually entered password
and cannot be used to auto-unlock.

Run `/usr/local/bin/autounlock_install_key.sh` to add or update keys on all
LUKS partitions defined in `/etc/crypttab`. Follow script prompts to finish setup.

## Add boot scripts

After adding keys to partitions you need to add correspondig scripts to do auto
unlock into initramfs. 

You need to have scripts in corresponding directories under `/etc/initramfs-tools/`.

Run `update-initramfs -k all -u` to update all kernel images.


## Try it out

Reboot :) If everything went smoothly - your system will boot without asking passwords at all.

Try disconnecting external monitor or turning off Wifi and rebooting again to
confirm that it asks for password to decode partitions.


## Removing extra keys

If you want to remove auto-unlock keys use `cryptsetup luksKillSlot /dev/sdaXXXX KEYSLOT`. 

KEYSLOT should be same slot you used while setting up auto-unlock keys. Do not
delete occasionally other slots, as you may be locked out of your system.

## Extra sources of information 

Adding extra information sources is pretty straightforward - just keep it in
sync between `etc/initramfs-tools/scripts/local-top/cryptroot-prepare:gather_key_information()`
and `usr/local/bin/autounlock_install_key.sh`. If you need extra
binaries/drivers in initramfs - add them into
`etc/initramfs-tools/hooks/prepare_auto_unlock_deps` script.

