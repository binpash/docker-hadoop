#!/bin/bash

# Determine the release tag
if [ "$1" == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi

# Set Docker client timeout
export DOCKER_CLIENT_TIMEOUT=300
export COMPOSE_HTTP_TIMEOUT=300

# Function to check if a service is running
function service_running() {
    local service_name="$1"
    docker service ls --filter "name=${service_name}" --format "{{.Name}}"
}

# Function to check if a network is created
function network_exists() {
    local network_name="$1"
    docker network ls --filter "name=${network_name}" --format "{{.Name}}"
}

# Build the Docker images
echo "Building the Docker images"
make build

# Setup the HBase network
echo "Setting up the HBase network"
if [ -z "$(network_exists hbase)" ]; then
    docker network create -d overlay --attachable hbase
else
    echo "Network 'hbase' already exists"
fi

# Setup a local image registry
echo "Setting up a local image registry"
# Label the current node (will be the manager node) for the registry service
# We can do this here because the IPs of pi nodes are fixed
# Without this the worker nodes can't seem to find the images in the registry

echo "Labeling the current node for registry service"
docker node update --label-add registry=true $(hostname)
registry_ip=$(hostname -i)
# registry_ip="localhost"

if [ -z "$(service_running registry)" ]; then
    docker service create --name registry --network hbase --publish published=5000,target=5000 registry:2
    # docker service create --name registry --publish published=5000,target=5000 --constraint 'node.labels.registry == true' registry:2 
else
    echo "Registry service is already running"
fi

# Check registry connection with debugging information
echo "Checking connection to the local Docker registry on $registry_ip:5000..."
curl_output=$(curl -s -o /dev/null -w "%{http_code}" http://"$registry_ip":5000/v2/)
if [ "$curl_output" != "200" ]; then
    echo "Error: Unable to connect to the local Docker registry. HTTP status code: $curl_output"
    echo "Debugging information:"
    curl -v http://"$registry_ip":5000/v2/
    exit 1
else
    echo "Successfully connected to the local Docker registry."
fi


# Push images to the local registry
images=(
    "hadoop-historyserver"
    "hadoop-nodemanager"
    "hadoop-resourcemanager"
    "hadoop-datanode"
    "hadoop-namenode"
    "hadoop-pash-base"
)

for image in "${images[@]}"; do
    echo "Pushing $image"
    docker image tag "$image:$RELEASE" "$registry_ip:5000/$image:$RELEASE"
    docker image push "$registry_ip:5000/$image:$RELEASE"

    if [ $? -ne 0 ]; then
        echo "Error pushing $image:$RELEASE to $registry_ip:5000/$image:$RELEASE"
        exit 1
    fi
done

# Ensure all nodes pull the images from the registry
echo "Pulling images on all nodes"
for node in $(docker node ls --format "{{.Hostname}}"); do
    echo "Pulling images on $node"
    ssh $node << EOF
        for image in hadoop-nodemanager hadoop-datanode; do 
            docker pull $registry_ip:5000/\$image:$RELEASE; 
        done
EOF
done


# Deploy the Swarm
echo "Deploying the Swarm"
docker stack deploy --with-registry-auth -c docker-compose-pi-v3.yml hadoop

# Generate the configuration
./gen_config.sh

echo "Deployment completed successfully."
