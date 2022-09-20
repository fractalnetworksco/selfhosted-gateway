#!/bin/bash
# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -e

SSH_HOST=$1
export LINK_DOMAIN=$2
export EXPOSE=$3
export WG_PRIVKEY=$(wg genkey)
# Nginx uses Docker DNS resolver for dynamic mapping of LINK_DOMAIN to link containers hostnames, see nginx/*.conf
# This is the magic.
# NOTE: All traffic for `*.subdomain.domain.tld`` will be routed to the container named `subdomain-domain-tld``
# Also supports `subdomain.domain.tld` as well as apex `domain.tld`
# *.domain.tld should resolve to the Gateway's public IPv4 address
export CONTAINER_NAME=$(echo $LINK_DOMAIN|python3 -c 'fqdn=input();print("-".join(fqdn.split(".")[-3:]))')


LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
LINK_ENV=$(ssh $SSH_HOST "bash -s" -- < ./_create-link.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)


source <(echo $LINK_ENV)

cat link-compose-snippet.yml | envsubst

# TODO add support for WireGuard config output
# Fractal Networks is hiring: jobs@fractalnetworks.co
