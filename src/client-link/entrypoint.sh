#!/bin/sh
set -euxo pipefail

echo $GATEWAY_CLIENT_WG_PRIVKEY > /etc/wireguard/link0.key


ip link add link0 type wireguard

wg set link0 private-key /etc/wireguard/link0.key
wg set link0 listen-port 18521
ip addr add 10.0.0.2/24 dev link0
ip link set link0 up
ip link set link0 mtu $LINK_MTU

wg set link0 peer $GATEWAY_LINK_WG_PUBKEY allowed-ips 10.0.0.1/32 persistent-keepalive 30 endpoint $GATEWAY_ENDPOINT

if [ -z ${FORWARD_ONLY+x} ]; then

    echo "Using caddy with SSL termination to forward traffic to app."
    if [ ! -z ${CADDY_TLS_PROXY+x} ]; then
        echo "Configure Caddy for use with TLS backend"
        if [ ! -z ${CADDY_TLS_INSECURE+x} ]; then
            echo "Skip TLS verification"
            export EXPOSE=$(cat <<-END
$EXPOSE {
         transport http {
            tls
            tls_insecure_skip_verify
            read_buffer 8192
         }
       }
END
)

        else
            export EXPOSE=$(cat <<-END
$EXPOSE {
         transport http {
            tls
            read_buffer 8192
         }
       }
END
)
        fi
    fi
    envsubst < /etc/Caddyfile.template > /etc/Caddyfile
    caddy run --config /etc/Caddyfile
else
    echo "Caddy is disabled. Using socat to forward traffic to app."
    socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:$EXPOSE,reuseaddr &
    socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:$EXPOSE_HTTPS,reuseaddr
fi

