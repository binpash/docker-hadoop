#!/bin/bash

##
## 1. Installs docker on all pi-hive machines in the manifest
## 2. Initializes a docker swarm in all of them
## 3. Installs docker-hadoop on the manager
##
## Invoke this script like this:
## `./prepare-pi-nodes.sh pi_username pi_passwd ~/.ssh/rsa_key_for_pi`
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
## Install docker on all cluster machines
##
clush --hostfile hostnames.txt -O ssh_options="-oStrictHostKeyChecking=no ${key_flag}" -l $user \
    -b "curl -fsSL https://get.docker.com -o get-docker.sh && \
        echo '$passwd' | sudo -S sh get-docker.sh && \
        echo '$passwd' | sudo -S sudo usermod -aG docker $user && \
        newgrp docker"

##
## Setup docker location
##
dockerd_config='echo -e "{\n\t\"data-root\": \"/mydata\"\n}"'
clush --hostfile hostnames.txt -l $user \
    -b "echo '$passwd' | sudo -S sudo bash -c '$dockerd_config > /etc/docker/daemon.json' && \
        echo '$passwd' | sudo -S service docker restart"
##
## Initialize a swarm from the manager
##
manager_hostname=$(head -n 1 hostnames.txt)
echo "Manager is: $manager_hostname"
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<ENDSSH
echo '${passwd}' | sudo -S docker swarm init --advertise-addr $(hostname -i)
# echo '${passwd}' | sudo -S docker swarm join-token worker
ENDSSH
} | tee swarm_advertise_output.txt

exit
join_command=$(cat swarm_advertise_output.txt | grep "docker swarm join --token" | sed 's/^/sudo/g')

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
echo '${passwd}' | sudo -S docker node ls
git clone -b ft-orig-optimized https://github.com/binpash/dish.git --recurse-submodules
cd dish/docker-hadoop

## Execute the setup with `nohup` so that it doesn't fail if the ssh connection fails
nohup echo '${passwd}' | sudo -S ./setup-swarm.sh --eval
ENDSSH