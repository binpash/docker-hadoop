#!/bin/bash

# Check if the node count is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <node_count>"
    exit 1
fi

# Configuration
NODE_COUNT=$1
LOG_DIR="./logs"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to run tasks on each machine
run_tasks() {
    local RUN_ID=$1
    for i in $(seq 0 $((NODE_COUNT-1))); do
        NODE_HOSTNAME="node$i"
        echo "Connecting to $NODE_HOSTNAME..."

        # Copy the remote script to the target machine synchronously
        scp -o StrictHostKeyChecking=no remote_commands.sh "$NODE_HOSTNAME:/tmp/remote_commands.sh"

        if [ "$RUN_ID" -eq 0 ]; then
            # Run the remote script and copy the worker log back to the current machine asynchronously
            ssh -o StrictHostKeyChecking=no "$NODE_HOSTNAME" "NODE_HOSTNAME='$NODE_HOSTNAME' bash /tmp/remote_commands.sh" && \
            scp -o StrictHostKeyChecking=no "$NODE_HOSTNAME:/tmp/worker_*.log" "$LOG_DIR/" && \
            ssh -o StrictHostKeyChecking=no "$NODE_HOSTNAME" 'rm /tmp/worker_*.log' &
        else
            # Run the remote script and remove the worker logs
            ssh -o StrictHostKeyChecking=no "$NODE_HOSTNAME" "NODE_HOSTNAME='$NODE_HOSTNAME' bash /tmp/remote_commands.sh" && \
            ssh -o StrictHostKeyChecking=no "$NODE_HOSTNAME" 'rm /tmp/worker_*.log' &
        fi
    done

    # Wait for all background processes to complete
    wait

    echo "All operations completed for run $RUN_ID."
}

# Run the tasks twice with a 10-second wait between them
run_tasks 0
sleep 10
run_tasks 1
sleep 10
