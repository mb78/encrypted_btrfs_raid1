# encrypted_btrfs_raid1
Helper script to setup/mount/umount (possibly) external (USB) disk(s) in RAID1 with encryption and BTRFS, e.g. for keeping git repos reasonably secured

HOWTO
* select 2 disks (e.g. partitions on USB drive) that CAN BE REWRITTEN
* update the script with UUIDs you found given them (`blkid`) and a password (e.g. hash of one you remember well)
* enable `sudo` for your account
* run: `./mount-mbdev-disk.sh -s` to initialize the disks/partitions
* `mount-mbdev-disk.sh -u` to umount or `./mount-mbdev-disk.sh -m` to get them mounted again

TODO
* disk device (e.g. /dev/sdb) may be lost, dm device might not be possible to remove, commands (x86-64 ubuntu 14.04) that didn't help enough:
  * `sudo umount -l mbdev`
  * `sudo dmsetup remove -f mbdev1`
  * `sudo cryptsetup luksClose mbdev1`
  * `lsblk` still shows mbdev1 as dm-2 and IDs 252:2, `lsof` didnt show anything about sdb, dm-2 or 252.2 (=regex)
* kernel logs after resuming from sleep-mode  
  `BTRFS: error (device dm-3) in btrfs_commit_transaction:2013: errno=-5 IO failure (Error while writing out transaction)`  
  `Call Trace:`  
  `[<ffffffff817b01b5>] dump_stack+0x45/0x57`
  `[<ffffffff81074dea>] warn_slowpath_common+0x8a/0xc0`  
 `[<ffffffff81074e66>] warn_slowpath_fmt+0x46/0x50`  
 `[<ffffffff810cae59>] ? vprintk_default+0x29/0x40`  
 `[<ffffffffc0396f14>] __btrfs_abort_transaction+0x54/0x130 [btrfs]`  
 `[<ffffffffc03c41ee>] cleanup_transaction+0x6e/0x2b0 [btrfs]`  
 `[<ffffffff810b4f60>] ? prepare_to_wait_event+0x110/0x110`  
 `[<ffffffff810b49f8>] ? __wake_up+0x48/0x60`  
 `[<ffffffffc03c4ef0>] btrfs_commit_transaction+0x270/0xa40 [btrfs]`  
 `[<ffffffffc03c09d5>] transaction_kthread+0x1b5/0x240 [btrfs]`  
 `[<ffffffffc03c0820>] ? btrfs_cleanup_transaction+0x570/0x570 [btrfs]`  
 `[<ffffffff810938d2>] kthread+0xd2/0xf0`  
 `[<ffffffff81093800>] ? kthread_create_on_node+0x1c0/0x1c0`  
 `[<ffffffff817b7b58>] ret_from_fork+0x58/0x90`  
 `[<ffffffff81093800>] ? kthread_create_on_node+0x1c0/0x1c0`
* btrfs module can't be unloaded, suspecting the mountpoint to be using btrfs
  `btrfs                 942080  1`  
  `xor                    24576  1 btrfs`  
  `raid6_pq               98304  1 btrfs`
