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

DISH_TOP=$(realpath $(dirname "$0")/..)
PASH_TOP=$(realpath $DISH_TOP/pash)

$PASH_TOP/scripts/setup-pash.sh
cp $DISH_TOP/docker-hadoop/dish-config.json $PASH_TOP/cluster.json

$DISH_TOP/runtime/scripts/build.sh

# https://docs.docker.com/compose/migrate
docker-compose up -d || docker compose up -d
