#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <EVAL_NAME> <MAX_ITERATIONS>"
    exit 1
fi

# Configurable variables from parameters
EVAL_NAME=$1
EVAL_PATH="/opt/dish/evaluation/$EVAL_NAME"
MAX_ITERATIONS=$2

# Docker container name
DOCKER_CONTAINER="docker-hadoop-client-1"

# Logs directory
LOGS_DIR="./logs"

# Create logs directory if it doesn't exist
mkdir -p $LOGS_DIR

# Iteration counter
iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
    # Delete the outputs folder inside the docker container
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $EVAL_PATH/outputs"
    
    # Run the first command inside the docker container and save output to a file
    docker exec $DOCKER_CONTAINER bash -c "$EVAL_PATH/run.sh" &> $LOGS_DIR/run_output.txt
    echo "Completed run.sh for iteration $iteration"
    
    # Run the verify command inside the docker container and save output to a file
    docker exec $DOCKER_CONTAINER bash -c "$EVAL_PATH/verify.sh" &> $LOGS_DIR/verify_output.txt
    echo "Completed verify.sh for iteration $iteration"

    # Run the helper script on the current machine and save output to a file
    ./helper.sh 30 &> $LOGS_DIR/helper_output.txt
    echo "Completed helper.sh for iteration $iteration"

    # Check if the verify.sh output contains the string "failed"
    if grep -q "failed" $LOGS_DIR/verify_output.txt; then
        echo "Verification failed. Exiting loop."
        exit 1
    fi

    # Print the iteration number completed
    iteration=$((iteration + 1))
    echo "Iteration $iteration completed."
done

echo "Completed $MAX_ITERATIONS iterations without failure."
