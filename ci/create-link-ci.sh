#!/bin/bash
set -e

cd ci/
ssh-keygen -t ed25519 -f ./gateway-sim-key -N ""
docker compose up -d --build
eval $(ssh-agent -s)
ssh-add ./gateway-sim-key
docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3
docker compose down