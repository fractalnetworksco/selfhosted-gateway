#!/bin/sh

WG_PRIVKEY=$(wg genkey)
echo $WG_PRIVKEY > /etc/wireguard/link0.key


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
socat UDP4-RECVFROM:18522,fork UDP4-SENDTO:10.0.0.2:18522,sp=18524,reuseaddr &
socat UDP4-RECVFROM:18523,fork UDP4-SENDTO:10.0.0.2:18522,sp=18525,reuseaddr
