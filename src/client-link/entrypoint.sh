#!/bin/sh
set -euxo pipefail

echo $GATEWAY_CLIENT_WG_PRIVKEY > /etc/wireguard/link0.key

cleanupLink() {
    if ip link show link0 > /dev/null 2>&1; then
        ip link delete link0
    fi
}

if ! ip link show link0 > /dev/null 2>&1; then
    trap cleanupLink EXIT
    ip link add link0 type wireguard
fi

wg set link0 private-key /etc/wireguard/link0.key
wg set link0 listen-port 18521
ip addr add 10.0.0.2/24 dev link0
ip link set link0 up
ip link set link0 mtu $LINK_MTU

wg set link0 peer $GATEWAY_LINK_WG_PUBKEY allowed-ips 10.0.0.1/32 persistent-keepalive 30 endpoint $GATEWAY_ENDPOINT

if [ -z ${FORWARD_ONLY+x} ]; then

    echo "Using caddy with SSL termination to forward traffic to app."
    if [ ! -z ${CADDY_TLS_PROXY+x} ]; then          # if CADDY_TLS_PROXY is set
        echo "Configure Caddy for use with TLS backend"
        if [ ! -z ${CADDY_TLS_INSECURE+x} ]; then   # if CADDY_TLS_INSECURE
            echo "Skip TLS verification"
            EXPOSE=$(cat <<-END
$EXPOSE {
         transport http {
            tls
            tls_insecure_skip_verify
            read_buffer 8192
         }
         header_up X-Forwarded-Proto {scheme}
       }
END
)

        else    # CADDY_TLS_INSECURE is false
            EXPOSE=$(cat <<-END
$EXPOSE {
         transport http {
            tls
            read_buffer 8192
         }
         header_up X-Forwarded-Proto {scheme}
       }
END
)
        fi
        else
         EXPOSE=$(cat <<-END
$EXPOSE {
         header_up X-Forwarded-Proto {scheme}
       }
END
)
    fi

    CADDYFILE='/etc/Caddyfile'
    BASIC_AUTH=${BASIC_AUTH:-}
    BASIC_AUTH_CONFIG=${BASIC_AUTH_CONFIG:-}
    TLS_INTERNAL_CONFIG=${TLS_INTERNAL_CONFIG:-}
    # Check if BASIC_AUTH is set and not empty
    if [[ ! -z "${BASIC_AUTH}" ]]; then
        # Assuming BASIC_AUTH contains username:hashed_password
        # Assuming BASIC_AUTH contains username:hashed_password
        USERNAME=$(echo "$BASIC_AUTH" | cut -d':' -f1)
        PASSWORD=$(echo "$BASIC_AUTH" | cut -d':' -f2)
        HASHED_PASSWORD=$(caddy hash-password --plaintext $PASSWORD)
        # Construct the basic auth configuration
        BASIC_AUTH_CONFIG=$(cat <<-END
            basicauth /* {
                ${USERNAME} ${HASHED_PASSWORD}
            }
END
        )
    fi
    export BASIC_AUTH_CONFIG
    # if TLS_INTERNAL is set export TLS_INTERNAL_CONFIG
    if [ ! -z ${TLS_INTERNAL+x} ]; then
        TLS_INTERNAL_CONFIG=$(cat <<-END
        tls internal
END
    )
    fi
    export EXPOSE
    export TLS_INTERNAL_CONFIG
    envsubst < /etc/Caddyfile.template > $CADDYFILE
    caddy run --config $CADDYFILE
else
    echo "Caddy is disabled. Using socat to forward traffic to app."
    socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:$EXPOSE,reuseaddr &
    socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:$EXPOSE_HTTPS,reuseaddr
fi
