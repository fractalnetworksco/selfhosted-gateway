#!/bin/bash
set -e
set -x

cd ci/
ssh-keygen -t ed25519 -f ./gateway-sim-key -N ""

docker network create gateway || true   # create docker network if not exists
docker compose up -d --build
eval $(ssh-agent -s)
ssh-add ./gateway-sim-key

# Test create-link
# generate a docker compose to test the generated link
cat test-link.template.yaml > test-link.yaml
docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> test-link.yaml
cat network.yaml >> test-link.yaml
# set the gateway endpoint to the gateway link container
sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' test-link.yaml

docker compose -f test-link.yaml up -d
docker compose -f test-link.yaml exec link ping 10.0.0.1 -c 2
# assert http response code was 200
# asserts basic auth is working with user: admin, password: admin

if ! docker compose exec gateway curl -k -H "Authorization: Basic YWRtaW46YWRtaW4=" --resolve app.example.com:443:127.0.0.1 https://app.example.com -I |grep "HTTP/2 200"; then
    FAILED="true"
fi
docker compose -f test-link.yaml down
docker rm -f app-example-com
rm test-link.yaml                 # comment out to keep the file for debugging


caddy_greenlight=true               # andrew's sentinel thing

if [ "$caddy_greenlight" = true ]; then
    echo "*******************Testing Caddy TLS Proxy"
    # Test the link using  CADDY_TLS_PROXY: true
    # generate new docker compose
    testLinkFile="test-link-caddyTLS.yaml"
    cat test-link.template.yaml > $testLinkFile
    docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> $testLinkFile
    cat network.yaml >> $testLinkFile

    # Go inside $testLinkFile and change...
    # gateway endpoint to the gateway link container
    sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' $testLinkFile

    # set CADDY_TLS_PROXY to true
    sed -i 's/^\(\s*\)#\s*CADDY_TLS_PROXY: true/\1CADDY_TLS_PROXY: true/' $testLinkFile

    docker compose -f $testLinkFile up -d
    docker compose -f $testLinkFile exec link ping 10.0.0.1 -c 2
    # assert http response code was 200
    # asserts basic auth is working with user: admin, password: admin

    if ! docker compose exec gateway curl -k -H "Authorization: Basic YWRtaW46YWRtaW4=" --resolve app.example.com:443:127.0.0.1 https://app.example.com -I |grep "HTTP/2 200"; then
        FAILED="true"
    fi
    docker compose -f $testLinkFile down
    docker rm -f app-example-com
    rm $testLinkFile                 # comment out to keep the file for debugging
fi


# stop and remove gateway and sshd containers
docker compose down

# if FAILED is true return 1 else 0
if [ ! -z ${FAILED+x} ]; then
    exit 1
fi
