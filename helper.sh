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
        HOSTNAME="node$i"
        echo "Connecting to $HOSTNAME..."

        # Copy the remote script to the target machine synchronously
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null remote_commands.sh "$HOSTNAME:/tmp/remote_commands.sh" 2>/dev/null

        if [ "$RUN_ID" -eq 0 ]; then
            # Run the remote script and copy the worker log back to the current machine asynchronously
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$HOSTNAME" 'bash /tmp/remote_commands.sh' 2>/dev/null && scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$HOSTNAME:/tmp/worker_*.log" "$LOG_DIR/" 2>/dev/null &
        else
            # Run the remote script asynchronously
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$HOSTNAME" 'bash /tmp/remote_commands.sh' 2>/dev/null &
        fi
    done

    # Wait for all background processes to complete
    wait

    echo "All operations completed for run $RUN_ID."
}

# Run the tasks twice with a 5-second wait between them
run_tasks 0
sleep 5
run_tasks 1
