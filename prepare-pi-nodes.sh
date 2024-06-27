#!/bin/bash

##
## 0. [Pre-requisite] Installs docker on all pi-hive machines in the manifest
## 1. Initializes a docker swarm in all of them
## 2. Installs docker-hadoop on the manager
##
## Invoke this script like this:
## `./prepare-pi-nodes.sh pi_username pi_passwd ~/.ssh/rsa_key_for_pi`
##
## where:
##  the first argument is the pi-cluster username
##  the second argument is the pi-cluster key optionally (if you pass that manually to ssh)

user=${1?"ERROR: No pi-cluster user given"}

## Optionally the caller can give us a private key for the ssh
key=$3
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

# Initialize the associative array with worker names and IP addresses
pi_cluster_nodes=(
    "worker0;10.116.70.108"
    "worker1;10.116.70.103"
    "worker2;10.116.70.109"
    "worker3;10.116.70.112"
    "worker4;10.116.70.105"
    "worker5;10.116.70.106"
    "worker6;10.116.70.107"
    "worker7;10.116.70.114"
)

# Create or clear the hostnames.txt file
> hostnames.txt

for pi_cluster_node in ${pi_cluster_nodes[@]}; do
    IFS=";" read -r -a pi_node_parsed <<< "${pi_cluster_node}"
    name="${pi_node_parsed[0]}"
    host="${pi_node_parsed[1]}"
    echo "${host}" >> hostnames.txt
done

echo "Hosts:"
cat hostnames.txt

##
## Initialize a swarm from the manager
##
manager_hostname=$(head -n 1 hostnames.txt)
echo "Manager is: $manager_hostname"
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
docker swarm init --advertise-addr $(hostname -i)
# docker swarm join-token worker
ENDSSH
} | tee swarm_advertise_output.txt

join_command=$(cat swarm_advertise_output.txt | grep "docker swarm join --token" | sed "s/[0-9.]\+:[0-9]\+/$manager_hostname/")


##
## Run join command on all swarm workers (execluding manager)
##
echo "join command is: " $join_command
clush --hostfile hostnames.txt -x "$manager_hostname" -O ssh_options="${key_flag}" -l "$user" -b $join_command

##
## Install our Hadoop infrastructure
##
ssh ${key_flag} -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
## Just checking that the workers have joined
docker node ls
git clone -b ft-orig-optimized https://github.com/binpash/dish.git --recurse-submodules
cd dish/docker-hadoop

## Execute the setup with `nohup` so that it doesn't fail if the ssh connection fails
nohup ./setup-pi-swarm.sh --eval
ENDSSH