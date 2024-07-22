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
    for i in $(seq 1 $NODE_COUNT); do
        HOSTNAME="node$i"
        echo "Connecting to $HOSTNAME..."

        # Copy the remote script to the target machine
        scp remote_commands.sh "$HOSTNAME:/tmp/remote_commands.sh"

        # Run the remote script
        ssh "$HOSTNAME" 'bash /tmp/remote_commands.sh'

        # Copy the worker log back to the current machine
        scp "$HOSTNAME:/tmp/worker_*.log" "$LOG_DIR/"
    done

    # Wait for all background processes to complete
    wait

    echo "All operations completed."
}

# Run the tasks twice with a 5-second wait between them
run_tasks
sleep 5
run_tasks
