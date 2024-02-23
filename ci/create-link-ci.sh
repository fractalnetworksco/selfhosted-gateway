#!/bin/bash
set -e
set -x

cd ci/
ssh-keygen -t ed25519 -f ./gateway-sim-key -N ""

docker network create gateway || true   # create docker network if not exists
docker compose up -d --build
eval $(ssh-agent -s)
ssh-add ./gateway-sim-key
# 
cat test-link.template.yaml > test-link.yaml
docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> test-link.yaml
cat network.yaml >> test-link.yaml
sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' test-link.yaml
docker compose -f test-link.yaml up -d
docker compose -f test-link.yaml exec link ping 10.0.0.1 -c 2

docker compose -f test-link.yaml down
docker rm -f app-example-com
rm test-link.yaml
