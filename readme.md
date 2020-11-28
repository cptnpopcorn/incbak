# Incremental Backup
This is a bash-based script that will create incremental backups on a locally connected drive.
## Motivation
For my home NAS, I need a simple backup solution, from the network storage to an external hard disk.
- I want to do this backup on a daily basis.
- I want the backup to be directly readable and usable, without additional tools or a cumbersome restoring process.
- I want to swap several external backup disks at any time, to keep them in different locations.
- The external disk is only slightly larger than the primary storage. Nevertheless, I want to keep multiple revisions.
- I have lots of media files, that are typically just stored but not modified further. I want to be able to re-organize them (by moving them around) without ending up with a 'disk full' on the backup drive. That means moved files shall not be treated as dumb deleted + created, but actually mirror-moved on the backup drive.
- I want to run this backup as a cron job on a daily basis and thus see errors logged on the error output, having those error reports logged or mailed by cron, if wanted.
## Requirements
- both source and destination file systems need to be locally accessible (mounted)
- both source and destination file systems need to provide hard links (such as ext4)
## Features
- the backup folders are directly readable, all backed-up data is fully available immediately
- multiple versions are kept as backups, with the granularity decreasing exponentially towards the past
- only new / changed files are actually copied (others will be hard-linked to the previous revision)
- files that did not change between revisions do not occupy additional space (by using hard-links)
## Backup Revisions
Revisions are maintained in generations. The first generation is updated for every backup, the second for every second, the third for every eigth etc.
The naming scheme is ``` destionation.N.X  ``` where N corresponds to the generation / step with ``` N = 1, 2, 4, 8, ... 128 ``` and ``` X = 0 | 1 ``` is just a binary counter to store the last state.
Example: ``` destination.4.1 ``` will be moved down to generation ``` destionation.8.0 ``` next time it will be updated to ``` destionation.4.0 ```. It will be updated with the contents of 'source' at every 4th backup.
## Usage
is quite simple ``` ./incbak.sh source destination ```
## Acknowledgments
I found the basic building blocks for the incremental, snapshot-style, rsync-based backup system with detection of moved files in these excellent sources
- http://www.mikerubel.org/computers/rsync_snapshots/ (incremental rsync backup using hard-links)
- https://github.com/dparoli/hrsync (tracking moved files using hard-link-based shadow copies)
