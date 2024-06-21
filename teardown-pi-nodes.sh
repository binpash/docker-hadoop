#!/bin/bash

##
## 1. Run the teardown script on the swarm manager node
##
## Invoke this script like this:
## `./teardown-pi-nodes.sh pi_username pi_passwd ~/.ssh/rsa_key_for_pi`
##
## where:
##  the first argument is the pi-cluster username
##  the second argument is the pi-cluster password
##  the third argument is the pi-cluster key optionally (if you pass that manually to ssh)

user=${1?"ERROR: No pi-cluster user given"}
passwd=${2?"ERROR: No pi-passwd given"}


pip install ClusterShell -q

## Optionally the caller can give us a private key for the ssh
key=$3
if [ -z "$key" ]; then
    key_flag=""
else
    key_flag="-i ${key}"
fi

## Run the teardown script on the swarm manager node
## Execute the teardown script with `nohup` so that it doesn't fail if the ssh connection fails
manager_hostname=$(head -n 1 hostnames.txt)
echo "Manager is: $manager_hostname"
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
nohup echo '${passwd}' | sudo -S ./stop-swarm.sh
ENDSSH
}

## TODO: Remove DiSh folder on all pi-cluster nodes