#!/bin/bash

cd "$(realpath $(dirname "$0"))"

if [ $1 == '--eval' ]; then
    export RELEASE="eval"
else
    export RELEASE="latest"
fi

# Check if DISH_TOP is set
if [ -z "$DISH_TOP" ]
then
    # If not set, assign a default path
    # export DISH_TOP=$(realpath $(dirname "$0")/../..)
    export DISH_TOP=/opt/fractal
fi

echo "Generating config"
./gen_config.sh

sudo apt install nginx -y
sudo systemctl enable nginx
hostname -f | sudo tee /var/www/html/hostname > /dev/null

# https://docs.docker.com/compose/migrate
docker compose -f docker-compose-client.yml up -d || docker-compose -f docker-compose-client.yml up -d
