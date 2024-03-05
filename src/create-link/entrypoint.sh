#!/bin/bash
# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -e

function fqdn_to_container_name() {
    local fqdn="$1"

    # Check if the FQDN is non-empty
    if [[ -z "$fqdn" ]]; then
        echo "Error: No FQDN provided."
        return 1
    fi

    # Replace all dots with dashes
    CONTAINER_NAME="${fqdn//./-}"

    echo "$CONTAINER_NAME"
}

SSH_HOST=$1
SSH_PORT=22
# split port from SSH_HOST if SSH_HOST contains :
if [[ $SSH_HOST == *":"* ]]; then
  IFS=':' read -ra ADDR <<< "$SSH_HOST"
  SSH_HOST=${ADDR[0]}
  SSH_PORT=${ADDR[1]}
fi

export LINK_DOMAIN=$2
export EXPOSE=$3
WG_PRIVKEY=$(wg genkey)
export WG_PRIVKEY
# Nginx uses Docker DNS resolver for dynamic mapping of LINK_DOMAIN to link container hostnames, see nginx/*.conf
# This is the magic.
# NOTE: All traffic for `*.subdomain.domain.tld`` will be routed to the container named `subdomain-domain-tld``
# Also supports `subdomain.domain.tld` as well as apex `domain.tld`
# *.domain.tld should resolve to the Gateway's access IPv4 address
CONTAINER_NAME=$(fqdn_to_container_name "$LINK_DOMAIN")
export CONTAINER_NAME

# get gateway access ipv4 address
GATEWAY_IP=$(getent ahostsv4 "$LINK_DOMAIN" | awk '{print $1; exit}')

LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
# LINK_ENV=$(ssh -o StrictHostKeyChecking=accept-new $SSH_HOST -p $SSH_PORT "bash -s" -- < ./remote.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY > /dev/null 2>&1)
LINK_ENV=$(ssh -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR $SSH_HOST -p $SSH_PORT "bash -s" -- < ./remote.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)

# convert to array
RESULT=($LINK_ENV)

export GATEWAY_LINK_WG_PUBKEY="${RESULT[0]}"
export GATEWAY_ENDPOINT="${GATEWAY_IP}:${RESULT[1]}"

# save snippet variables to .env file
cat link-compose-snippet.env | envsubst > "/workdir/${CONTAINER_NAME}.env"
echo "# docker compose --env-file ./${CONTAINER_NAME}.env ..."

cat link-compose-snippet.yml | envsubst

# TODO add support for WireGuard config output
# Fractal Networks is hiring: jobs@fractalnetworks.co
