#!/bin/sh
set -euxo pipefail

echo $GATEWAY_CLIENT_WG_PRIVKEY > /etc/wireguard/link0.key


ip link add link0 type wireguard

wg set link0 private-key /etc/wireguard/link0.key
wg set link0 listen-port 18521
ip addr add 10.0.0.2/24 dev link0
ip link set link0 up

wg set link0 peer $GATEWAY_LINK_WG_PUBKEY allowed-ips 10.0.0.1/32 persistent-keepalive 30 endpoint $GATEWAY_ENDPOINT

envsubst < /etc/Caddyfile.template > /etc/Caddyfile
caddy run --config /etc/Caddyfile
