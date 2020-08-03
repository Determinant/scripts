#!/bin/bash
source /home/ymf/.ssh/rsync_passwd.sh
export RSYNC_PASSWORD="ymf_ymf"
/home/ymf/scripts/backup.py -u
function remote_exec {
    ssh root@pandora-local -i /home/ymf/.ssh/id_rsa_home "$@"
}
remote_exec /home/ymf/create_auto_snapshots.sh
remote_exec /home/ymf/clean_auto_snapshots.sh
