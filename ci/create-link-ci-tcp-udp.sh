#!/bin/bash
set -e
# set -x        # uncomment for debugging

make setup || true
make docker

cd ci/
yes| ssh-keygen -t ed25519 -f ./gateway-sim-key -N ""

docker compose up -d --build
eval $(ssh-agent -s)
ssh-add ./gateway-sim-key


testLinkFile=""   # Define the variable in a scope outside the cleanup function

# Function to catch and cleanup containers/files if the script fails or is terminated prematurely.
# Good for local testing, eliminates the need to manually remove docker containers.
function cleanup {
    if [[ -n "$testLinkFile" ]]; then  # Check if the variable is non-empty
        echo "******* Cleanup function: cleaning up $testLinkFile..."
        docker compose -f "$testLinkFile" down --timeout 0 || true
        docker rm -f app-example-com || true
        docker rm -f ci-link-1 > /dev/null
        docker rm -f nc-server > /dev/null
        # stop and remove gateway and sshd containers
        docker compose down --timeout 0 || true
        rm "$testLinkFile" || true
    fi
}
trap cleanup ERR
trap cleanup EXIT

# Default Link test
normal_test_proceed=true
if [ "$normal_test_proceed" = true ]; then
    echo "******************* Test TCP Tunnel Link *******************"
    testLinkFile="test-link-tcp-udp.yaml"

    # generate a docker compose using templates + output
    cat test-link-tcp-udp.template.yaml > $testLinkFile
    docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> $testLinkFile
    cat network.yaml >> $testLinkFile
    # set the gateway endpoint to the gateway link container
    sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' $testLinkFile

    docker compose -f $testLinkFile up -d --wait

    docker compose -f $testLinkFile exec link ping 10.0.0.1 -c 1 # Is this necessary if I have two containers to test the connection?

    # try to send a TCP packet to the nc-server container through the gateway container bound to port 8080 on the host
    if [ $(docker run --rm --network=host --entrypoint="/bin/sh" subfuzion/netcat -c "echo foo | nc -N -w1 localhost 8080"> /dev/null; echo $?) -ne 0 ]
    then
        FAILED="true"
        echo -e "\033[0;31m TCP TUNNEL FAILED\033[0m"     # red for failure
    else
        echo -e "\033[0;32m TCP TUNNEL SUCCESS\033[0m"     # green for success
    fi

    # remove test link so the next test can recreate it
    rm $testLinkFile
    docker rm -f app-example-com > /dev/null # It wasn't getting cleaned up for the second test
else
    echo "******************* Skipping normal link test... \n(normal_test_greenlight was false)"
fi

# Default Link test
normal_test_proceed=true
if [ "$normal_test_proceed" = true ]; then
    echo "******************* Test UDP Tunnel Link *******************"
    testLinkFile="test-link-tcp-udp.yaml"

    # generate a docker compose using templates + output
    cat test-link-tcp-udp.template.yaml > $testLinkFile
    docker run --network gateway -e SSH_AGENT_PID=$SSH_AGENT_PID -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK --rm fractalnetworks/gateway-cli:latest $1 $2 $3 >> $testLinkFile
    cat network.yaml >> $testLinkFile
    # set the gateway endpoint to the gateway link container
    sed -i 's/^\(\s*GATEWAY_ENDPOINT:\).*/\1 app-example-com:18521/' $testLinkFile

    docker compose -f $testLinkFile up -d --wait

    docker compose -f $testLinkFile exec link ping 10.0.0.1 -c 1 # Is this necessary if I have two containers to test the connection?
   
    #Try to send a UDP packet to the nc-server container through the gateway container bound to port 8080 on the host
    if [ $(docker run --rm --network=host --entrypoint="/bin/sh" subfuzion/netcat -c "echo foo | nc -Nu -w1 localhost 8080"> /dev/null; echo $?) -ne 0 ]
    then
        FAILED="true"
        echo -e "\033[0;31m UDP TUNNEL FAILED\033[0m"     # red for failure
    else
        echo -e "\033[0;32m UDP TUNNEL SUCCESS\033[0m"     # green for success
    fi

    # remove test link so the next test can recreate it
    rm $testLinkFile
else
    echo "******************* Skipping normal link test... \n(normal_test_greenlight was false)"
fi


# if FAILED is true return 1 else 0
if [ ! -z ${FAILED+x} ]; then
    exit 1
fi
