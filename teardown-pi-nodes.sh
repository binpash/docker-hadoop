#!/bin/bash

##
## 1. Remove the Stack, Services, and Network
## 2. Let worker nodes leave the swarm
## 3. Let the manager node leave the swarm
## 4. Remove dish/ folder for the manager node and all worker nodes

## Invoke this script like this:
## `./teardown-pi-nodes.sh pi_username ~/.ssh/rsa_key_for_pi`
##
## where:
##  the first argument is the pi-cluster username
##  the second argument is the pi-cluster key optionally (if you pass that manually to ssh)

user=${1?"ERROR: No pi-cluster user given"}

## Optionally the caller can give us a private key for the ssh
key=$2
if [ -z "$key" ]; then
    key_flag=""
else
    key_flag="-i ${key}"
fi

# Check if the clustershell package is installed
if dpkg -s clustershell &> /dev/null; then
    echo "clustershell is already installed."
else
    echo "clustershell is not installed. Installing..."
    sudo apt update && yes | sudo apt install clustershell
fi


## Remove the Stack, Services, and Network
## Execute the teardown script with `nohup` so that it doesn't fail if the ssh connection fails
echo "Remove the Stack, Services, and Network"
manager_hostname=$(head -n 1 hostnames.txt)
echo "Manager is: $manager_hostname"
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
cd dish/docker-hadoop
docker compose -f docker-compose-client.yml down
nohup ./stop-swarm.sh
ENDSSH
}

## Remove worker nodes from the swarm
echo "Removing all worker nodes from the swarm"
clush --hostfile hostnames.txt -x "$manager_hostname" -O ssh_options="${key_flag}" -l "$user" -b "docker swarm leave"

## Remove the manager node from the swarm
echo "Removing the manager node from the swarm"
manager_hostname=$(head -n 1 hostnames.txt)
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
docker swarm leave --force
ENDSSH
}


## TODO: Remove DiSh folder on all pi-cluster nodes (workers and the manager)
echo "Removing the dish folder on all pi-cluster nodes"
clush --hostfile hostnames.txt -O ssh_options="${key_flag}" -l "$user" -b "rm -rf dish"