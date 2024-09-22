#!/bin/bash

##
## 1. Remove the Stack, Services, and Network
## 2. Let worker nodes leave the swarm
## 3. Let the manager node leave the swarm
## 4. Remove dish/ folder for the manager node and all worker nodes

## Invoke this script like this:
## `./teardown-cloudlab-nodes.sh cloudlab-username
## where:
##  the first argument is the cloudlab username
##  the second argument is the cloudlab key optionally (if you pass that manually to ssh)

user=${1?"ERROR: No cloudlab user given"}

## Optionally the caller can give us a private key for the ssh
key=$2
if [ -z "$key" ]; then
    key_flag=""
else
    key_flag="-i ${key}"
fi

# Check if clush command is available
if command -v clush &> /dev/null; then
    echo "clush is already installed."
else
    echo "Error: clush is not installed. Please install clustershell to proceed." >&2
    exit 1
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
echo "Removing the dish folder on all cloudlab-cluster nodes"
clush --hostfile hostnames.txt -O ssh_options="${key_flag}" -l "$user" -b "rm -rf dish"

echo "Pruning all docker images and volumes"
clush --hostfile hostnames.txt -O ssh_options="${key_flag}" -l "$user" -b "docker system prune -a --volumes -f"