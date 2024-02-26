#!/bin/bash
set -e
set -x

cd ci/
ssh-keygen -t ed25519 -f ./gateway-sim-key -N ""

docker network create gateway || true   # create docker network if not exists
docker compose up -d --build
eval $(ssh-agent -s)
ssh-add ./gateway-sim-key
# generate a docker compose to test the generated link
cat test-link.template.yaml > test-link.yaml
docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> test-link.yaml
cat network.yaml >> test-link.yaml
# set the gateway endpoint to the gateway link container
sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' test-link.yaml
docker compose -f test-link.yaml up
docker compose -f test-link.yaml exec link ping 10.0.0.1 -c 2
# assert http response code was 200
# asserts basic auth is working with user: admin, password: admin

if ! docker compose exec gateway curl -k -H "Authorization: Basic YWRtaW46YWRtaW4=" --resolve app.example.com:443:127.0.0.1 https://app.example.com -I |grep "HTTP/2 200"; then
    FAILED="true"
fi
docker compose -f test-link.yaml down
docker rm -f app-example-com
rm test-link.yaml
docker compose down

# if FAILED is true return 1 else 0
if [ ! -z ${FAILED+x} ]; then
    exit 1
fi
