#!/bin/bash

set -e

CONTAINER_NAME=$1
LINK_CLIENT_WG_PUBKEY=$2
FORWARD_PORT=$3
FORWARD_PROTOCOL=$4
BACK_PORT=$5


get_random_port() {
    # create gateway-link container
    CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p 18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
    # get randomly assigned WireGuard port
    echo $(docker port $CONTAINER_NAME 18521/udp| head -n 1| sed "s/0\.0\.0\.0://")

    docker rm -f $CONTAINER_ID 2>& 1>NUL
}

WIREGUARD_PORT="$(get_random_port)"
CENTER_PORT="$(get_random_port)"

# create gateway-link container
if [ -n "$FORWARD_PORT" ] && [ -n "$FORWARD_PROTOCOL" ]
then
    CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p $WIREGUARD_PORT:18521/udp -p $FORWARD_PORT:$CENTER_PORT/tcp -p $FORWARD_PORT:$CENTER_PORT/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest $FORWARD_PORT $FORWARD_PROTOCOL $CENTER_PORT)
else
    CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p $WIREGUARD_PORT:18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
fi
# get gateway-link WireGuard pubkey 
GATEWAY_LINK_WG_PUBKEY=$(docker exec $CONTAINER_NAME bash -c 'cat /etc/wireguard/link0.key |wg pubkey')


echo "$GATEWAY_LINK_WG_PUBKEY $WIREGUARD_PORT $CENTER_PORT"
