export LINK_DOMAIN=$1
export EXPOSE=$2
export WG_PRIVKEY=$3
export GATEWAY_ENDPOINT=$4
cat link-compose-snippet.yml | envsubst