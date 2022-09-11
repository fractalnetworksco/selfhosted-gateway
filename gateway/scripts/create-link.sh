# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub $WG_PRIVKEY

set -euo pipefail

SSH_HOST=$1
export LINK_DOMAIN=$2
export CONTAINER_NAME=$3
export EXPOSE=$4
export WG_PRIVKEY=$(wg genkey)


LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
LINK_ENV=$(ssh $SSH_HOST "bash -s" -- < ./_create-link.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)


source <(echo $LINK_ENV)

cat link-compose-snippet.yml | envsubst
