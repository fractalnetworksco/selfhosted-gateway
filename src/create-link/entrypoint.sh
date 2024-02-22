#!/bin/bash
# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -e

SSH_HOST=$1
SSH_PORT=22
# split port from SSH_HOST if SSH_HOST contains :
if [[ $SSH_HOST == *":"* ]]; then
  IFS=':' read -ra ADDR <<< "$SSH_HOST"
  SSH_HOST=${ADDR[0]}
  SSH_PORT=${ADDR[1]}
fi
echo $SSH_HOST
echo $SSH_PORT
export LINK_DOMAIN=$2
export EXPOSE=$3
export WG_PRIVKEY=$(wg genkey)
# Nginx uses Docker DNS resolver for dynamic mapping of LINK_DOMAIN to link container hostnames, see nginx/*.conf
# This is the magic.
# NOTE: All traffic for `*.subdomain.domain.tld`` will be routed to the container named `subdomain-domain-tld``
# Also supports `subdomain.domain.tld` as well as apex `domain.tld`
# *.domain.tld should resolve to the Gateway's public IPv4 address
export CONTAINER_NAME=$(echo $LINK_DOMAIN|python3 -c 'fqdn=input();print("-".join(fqdn.split(".")[-4:]))')


LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
LINK_ENV=$(ssh -o StrictHostKeyChecking=accept-new $SSH_HOST -p $SSH_PORT "bash -s" -- < ./remote.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)

# convert to array
RESULT=($LINK_ENV)

export GATEWAY_LINK_WG_PUBKEY=${RESULT[0]}
export GATEWAY_ENDPOINT=${RESULT[1]}

cat link-compose-snippet.yml | envsubst

# TODO add support for WireGuard config output
# Fractal Networks is hiring: jobs@fractalnetworks.co
