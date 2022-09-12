#!/bin/bash
set -euo pipefail

CONTAINER_NAME=$1
LINK_CLIENT_WG_PUBKEY=$2

# create gateway-link container
CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p 18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
sleep 5
# get gateway-link WireGuard pubkey 
GATEWAY_LINK_WG_PUBKEY=$(docker exec $CONTAINER_NAME bash -c 'cat /etc/wireguard/link0.key |wg pubkey')
echo export GATEWAY_LINK_WG_PUBKEY=$GATEWAY_LINK_WG_PUBKEY
# get randomly assigned WireGuard port
WIREGUARD_PORT=$(docker port $CONTAINER_NAME 18521/udp |head -n 1)
WIREGUARD_PORT=$(echo $WIREGUARD_PORT|sed "s/0\.0\.0\.0://")
# get public ipv4 address
GATEWAY_IP=$(curl -s 4.icanhazip.com)
echo export GATEWAY_ENDPOINT=$GATEWAY_IP:$WIREGUARD_PORT

