#!/bin/bash
for arg in "$@"
do
    if [ "$arg" == '--eval' ]; then
        export RELEASE="eval"
    elif [ "$arg" == '--no-cache' ]; then
        export NO_CACHE=1
    fi
done

## TODO: This should not build the images by default, but should just download them
make build

# https://docs.docker.com/compose/migrate
docker-compose up -d || docker compose up -d
