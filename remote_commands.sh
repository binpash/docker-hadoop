#!/bin/bash

# Function to handle container tasks
handle_container() {
    local CONTAINER_NAME=$1
    local MAIN=$2

    # Find the container ID
    CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}")

    if [ -z "$CONTAINER_ID" ]; then
        return 1
    fi

    # Collect /worker.log from the container
    docker cp "$CONTAINER_ID:/worker.log" "/tmp/worker.log"

    # Get the private IP from the worker.log
    PRIVATE_IP=$(head /tmp/worker.log | grep "Worker running on" | awk '{print $4}' | cut -d':' -f1)

    if [ -z "$PRIVATE_IP" ]; then
        echo "No private IP found in worker.log for container $CONTAINER_ID on $NODE_HOSTNAME"
        return 1
    fi

    # Save the worker.log with the private IP and hostname as the filename
    mv /tmp/worker.log "/tmp/worker_${PRIVATE_IP}_${NODE_HOSTNAME}.log"

    if [ "$MAIN" = "true" ]; then
        # Run /opt/dish/update.sh --main inside the container
        docker exec "$CONTAINER_ID" /opt/dish/update.sh --main
    else
        # Run /opt/dish/update.sh inside the container
        docker exec "$CONTAINER_ID" /opt/dish/update.sh
    fi
    return 0
}

# Check for hadoop container first and handle it, otherwise check for main container
if ! handle_container "hadoop_datanode" false; then
    if ! handle_container "docker-hadoop-client-1" true; then
        echo "No suitable container found on $NODE_HOSTNAME"
    fi
fi
