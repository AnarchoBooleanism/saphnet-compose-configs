#!/bin/bash
# Ensure the network directory of the Pterodactyl Wing is mounted

export LOCAL_MOUNT_PATH="/mnt/pterodactyl-data"
export NFS_HOST="nas1.int-net.saphnet.xyz"
export NFS_PATH="/mnt/saphnet-nas1a/pterodactyl-data"

mkdir -p $LOCAL_MOUNT_PATH

if ! grep -qs "$LOCAL_MOUNT_PATH" filename ; then
  mount -t nfs -o addr=$NFS_HOST,nolock,soft,rw,nfsvers=4 \
    $NFS_HOST:$NFS_PATH $LOCAL_MOUNT_PATH
fi

