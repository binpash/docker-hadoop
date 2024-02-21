#!/bin/bash
if [ $1 == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi

# Check if DISH_TOP is set
if [ -z "$DISH_TOP" ]
then
    # If not set, assign a default path
    export DISH_TOP=$(realpath $(dirname "$0")/../..)
fi

echo "Generating config"
./gen_config.sh

# https://docs.docker.com/compose/migrate
docker compose -f docker-compose-client.yml up -d || docker-compose -f docker-compose-client.yml up -d
