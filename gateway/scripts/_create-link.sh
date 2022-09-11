#!/bin/bash
set -euo pipefail
# launch gateway
#docker run --network gateway  -p 80:80 -p 443:443 -e GATEWAY_DOMAIN=selfhosted.pub -e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx -it fractalnetworks/gateway:latest
DOMAIN=$1
LINK_CLIENT_WG_PUBKEY=$2

# create gateway-link container
CONTAINER_ID=$(docker run --name $DOMAIN --network gateway -p 18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)

# get gateway-link WireGuard pubkey 
GATEWAY_LINK_WG_PUBKEY=$(docker exec $DOMAIN bash -c 'cat /etc/wireguard/link0.key |wg pubkey')
echo export GATEWAY_LINK_WG_PUBKEY=$GATEWAY_LINK_WG_PUBKEY
# get randomly assigned WireGuard endpoint port
WIREGUARD_PORT=$(docker port $DOMAIN 18521/udp |head -n 1)
WIREGUARD_PORT=$(echo $WIREGUARD_PORT|sed "s/0\.0\.0\.0://")
# get public ipv4 address
GATEWAY_IP=$(curl -s 4.icanhazip.com)
echo export GATEWAY_ENDPOINT=$GATEWAY_IP:$WIREGUARD_PORT

