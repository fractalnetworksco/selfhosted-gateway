#!/bin/sh

KEY_PATH="/etc/wireguard/link0.key"

FORWARD_PORT=$1
CENTER_PORT=$3

if [ ! -f "$KEY_PATH" ]; then
    WG_PRIVKEY=$(wg genkey)
    echo $WG_PRIVKEY > "$KEY_PATH"
else
    echo "A WireGuard private key already exists at $KEY_PATH."
fi


ip link add link0 type wireguard

wg set link0 private-key /etc/wireguard/link0.key
wg set link0 listen-port 18521
ip addr add 10.0.0.1/24 dev link0
ip link set link0 up
ip link set link0 mtu $LINK_MTU

wg set link0 peer $LINK_CLIENT_WG_PUBKEY allowed-ips 10.0.0.2/32

#iptables forward port 80, 443 to 10.0.0.2:80/443
iptables -A FORWARD -i eth0 -o link0 -p tcp --syn --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o link0 -p tcp --syn --dport 443 -m conntrack --ctstate NEW -j ACCEPT

iptables -A FORWARD -i eth0 -o link0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i link0 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.0.0.2:8080
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 10.0.0.2:8443

iptables -t nat -A POSTROUTING -o link0 -p tcp --dport 8080 -j SNAT --to-source 10.0.0.1
iptables -t nat -A POSTROUTING -o link0 -p tcp --dport 8443 -j SNAT --to-source 10.0.0.1

# generic udp proxies

# $1 is the forwarded port
if [ -z "$FORWARD_PORT" ]
then
    socat UDP4-RECVFROM:18522,fork UDP4-SENDTO:10.0.0.2:18522,sp=18524,reuseaddr &
    socat UDP4-RECVFROM:18523,fork UDP4-SENDTO:10.0.0.2:18522,sp=18525,reuseaddr
else
    # Just opening both TCP and UDP is the quick and dirty way of ensuring both protocols work
    # In the future, specifying a protocol in the docker compose snippet may be necessary
    # -- 2024-04-03 Zach
    socat TCP4-LISTEN:$CENTER_PORT,fork,reuseaddr TCP4:10.0.0.2:$CENTER_PORT,reuseaddr &
    socat UDP4-LISTEN:$CENTER_PORT,fork,reuseaddr UDP4:10.0.0.2:$CENTER_PORT,reuseaddr
fi
#socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:$EXPOSE_HTTPS,reuseaddr
