#!/bin/bash

set -e

CONTAINER_NAME=$1
LINK_CLIENT_WG_PUBKEY=$2
FORWARD_PORT=$3
FORWARD_PROTOCOL=$4

# create gateway-link container
CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p 18521/udp -p 25565/tcp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
# get randomly assigned WireGuard port
WIREGUARD_PORT=$(docker port $CONTAINER_NAME 18521/udp| head -n 1| sed "s/0\.0\.0\.0://")

docker rm -f $CONTAINER_ID 2>& 1>NUL

# create gateway-link container
CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p $WIREGUARD_PORT:18521/udp -p $FORWARD_PORT:$FORWARD_PORT/$FORWARD_PROTOCOL --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
# get gateway-link WireGuard pubkey 
GATEWAY_LINK_WG_PUBKEY=$(docker exec $CONTAINER_NAME bash -c 'cat /etc/wireguard/link0.key |wg pubkey')
# get randomly assigned WireGuard port
#WIREGUARD_PORT=$(docker port $CONTAINER_NAME 18521/udp| head -n 1| sed "s/0\.0\.0\.0://")

echo "$GATEWAY_LINK_WG_PUBKEY $WIREGUARD_PORT"
