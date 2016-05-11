# encrypted_btrfs_raid1
Helper script to setup/mount/umount (possibly) external (USB) disk(s) in RAID1 with encryption and BTRFS, e.g. for keeping git repos reasonably secured

HOWTO
* select 2 disks (e.g. partitions on USB drive) that CAN BE REWRITTEN
* update the script with UUIDs you found given them (`blkid`) and a password (e.g. hash of one you remember well)
* enable `sudo` for your account
* run: `./mount-mbdev-disk.sh -s` to initialize the disks/partitions
* `mount-mbdev-disk.sh -u` to umount or `./mount-mbdev-disk.sh -m` to get them mounted again
