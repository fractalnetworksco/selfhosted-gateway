# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -euo pipefail
# convert fqdn to container name
export CONTAINER_NAME=$(echo $LINK_DOMAIN|python3 -c 'fqdn = input(); print("-".join(fqdn.split(".")[-3:]))')

SSH_HOST=$1
export LINK_DOMAIN=$2
export EXPOSE=$3
export WG_PRIVKEY=$(wg genkey)

LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
LINK_ENV=$(ssh $SSH_HOST "bash -s" -- < ./_create-link.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)

source <(echo $LINK_ENV)

cat link-compose-snippet.yml | envsubst
