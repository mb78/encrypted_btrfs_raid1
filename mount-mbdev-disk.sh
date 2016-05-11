#!/bin/bash

# Manage disk as source of encrypted RAID1 FS with btrfs.
#
# The diagram of logical layers:
# ------------------------------------------
#               BTRFS, RAID1
# ------------------------------------------
#  LUKS, /dev/mapper/<LUKS_DEV_PREFIX>{1,2}
# ------------------------------------------
#        2 DEVICES, /dev/<SETUP_DEVS>
# ------------------------------------------

# Customisation
LABEL="mbdev"
UUID1="36d5d0e6-7a4d-416f-bc00-ec8d1103d86d"
UUID2="33fb85cd-8660-477f-88cd-2a8f978f6846"
SETUP_DEVS="$(echo -n $(blkid | egrep "UUID=.($UUID1|$UUID2)" | cut -d: -f1))"
# hint, use: echo -n YOUR_SECRET | md5sum
PASSWORD="fd863c2835e9e2bef63eabf159f72695"

# {{{
LUKS_DEV_PREFIX="$LABEL"
MOUNT_DIR="$HOME/$LABEL"

function error()
{
	echo -e "ERROR: $@" >&2
	exit 1
}


function log()
{
	echo -e "INFO: $@"
}


function cmd()
{
	sudo "$@" 2>&1 | sed 's/^/  | /'
	return ${PIPESTATUS[0]}
}


function do_setup()
{
	set -e
	cmd test ! -e /dev/mapper/${LUKS_DEV_PREFIX}1 || error "/dev/mapper/${LUKS_DEV_PREFIX}1 exists"
	cmd test ! -e /dev/mapper/${LUKS_DEV_PREFIX}2 || error "/dev/mapper/${LUKS_DEV_PREFIX}2 exists"
	echo -e "\033[31;1mDo you want to setup LUKS/BTRFS on devices: $SETUP_DEVS ?\033[m"
	echo "... press ENTER to continue or Ctrl-C to stop"
	read
	for i in $SETUP_DEVS; do
		log "Setup encryption on $i"
		echo $PASSWORD | cmd cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random luksFormat $i
#		grep -qr $UUID /etc/udev && error "Device with UUID=$UUID is already registered in udev"
#		sudo echo 'KERNEL=="sd*", ENV{ID_FS_UUID}=="'$UUID'", ENV{ID_FS_LABEL}="Partition_1", ENV{ID_FS_LABEL_ENC}="Partition_1"
	done
	INDEX=1
	for i in $SETUP_DEVS; do
		log "Open device $i as /dev/mapper/${LUKS_DEV_PREFIX}$INDEX"
		echo $PASSWORD | cmd cryptsetup luksOpen $i ${LUKS_DEV_PREFIX}$INDEX
		let INDEX++
	done
	log "Create BTRFS in RAID1 on ${LUKS_DEV_PREFIX}{1,2}"
	cmd mkfs.btrfs -m raid1 -d raid1 -f /dev/mapper/${LUKS_DEV_PREFIX}{1,2}
	log "Create mountdir $MOUNT_DIR and mount filesystem there"
	cmd mkdir -p $MOUNT_DIR
	cmd mount /dev/mapper/${LUKS_DEV_PREFIX}1 $MOUNT_DIR
	log "Label $MOUNT_DIR with '$LABEL'"
	cmd btrfs filesystem label $MOUNT_DIR $LABEL
	log "Disk-free ala BTRFS:"
	cmd chown $USER:$(id -ng) $MOUNT_DIR
	cmd btrfs fi df $MOUNT_DIR
}


function do_mount()
{
	set -e
	mount | grep -q "$MOUNT_DIR.* btrfs" && { log "\033[32;1m$MOUNT_DIR is already mounted with BTRFS\033[m"; exit 0; }
	log "Create $MOUNT_DIR (if does not exist)"
	mkdir -p $MOUNT_DIR
	log "Setup dev-mapper devices /dev/mapper/${LUKS_DEV_PREFIX}1/2"
	INDEX=1
	for i in $SETUP_DEVS; do
		echo $PASSWORD | cmd cryptsetup luksOpen $i ${LUKS_DEV_PREFIX}$INDEX
		let INDEX++
	done
	log "Create mountdir $MOUNT_DIR and mount filesystem there"
	cmd mkdir -p $MOUNT_DIR
	cmd mount /dev/mapper/${LUKS_DEV_PREFIX}1 $MOUNT_DIR
	cmd btrfs fi df $MOUNT_DIR
}


function do_umount()
{
	log "Unmount $MOUNT_DIR if exists"
	cmd umount $MOUNT_DIR
	log "Drop mapper devices /dev/mapper/${LUKS_DEV_PREFIX}1/2"
	cmd cryptsetup luksClose ${LUKS_DEV_PREFIX}1
	cmd cryptsetup luksClose ${LUKS_DEV_PREFIX}2
}
# }}}

echo "$SETUP_DEVS" | egrep -q "^/dev/sd[b-f][1-9] /dev/sd[b-f][1-9]$" || error \
	"No device found by UUIDs $UUID1/$UUID2\n" \
	"Devices:\n" \
	"$(blkid)\n" \
	"Set UUIDs with following command for your devices and update me ($0):" \
	"  cryptsetup luksUUID --uuid \$(uuidgen) /dev/sdZZZ"

[ "$1" = "-s" ] && do_setup
[ "$1" = "-m" ] && do_mount
[ "$1" = "-u" ] && do_umount
