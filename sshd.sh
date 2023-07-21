#!/bin/bash


# setup signal trap for graceful s3 disconnect
. trap.sh

# this the lockfile doesn't exist (first time only)
if [[ ! -f /etc/ssh/lockfile ]]; then
    # append the ssh key
    cat "/etc/ssh/host_pubkey" >> "/etc/ssh/authorized_keys"
    # generate our keys. we want to make sure these don't
    # get reset every time we stop and start the container
    ssh-keygen -A
fi

# start sshd
/usr/sbin/sshd -De
