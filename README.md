# Self-hosted Fractal Gateway

This is a lighweight implementation of the Fractal Gateway RPoVPN.

It combines Docker, Nginx and WireGuard in a novel way to enable self-hosted connectivity to your self-hosted applications.

Inspired by: http://widgetsandshit.com/teddziuba/2010/10/taco-bell-programming.html

And: https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2

Similar products:
- Cloudflare Argo Tunnels
- ngrok
- Inlets
- Pagekite
- Tailscale
- Zerotier

## Reverse Proxy-over-VPN (RPoVPN)
1. **RPoVPN is a common strategy for self-hosting publicly accessible services from home while elimating the need for complex local network configuration changes such as:**
  - Opening ports on your local Internet router or firewall
  - Using a dynamic DNS provider due to a lack of a static IP
  - Self-hosting via an ISP that deploys CGNAT (Starlink, T-mobile Home Internet)

2. **Using RPoVPN is ideal for self-hosting from both a network security and privacy perspective:**
  - RPoVPN eliminates the need to expose your home IP address to the public.
  - Fractal Gateway RPoVPN uses advanced network isolation capabilities of the Linux kernel (network namespaces) to keep self-hosted services isolated from your home network and your other local / self-hosted services.

## Dependencies
- A custom apex domain for example **selfhosted.pub** 
- Publicly accessible host with open tcp ports 80/443 and udp port range `/proc/sys/net/ipv4/ip_local_port_range`
- SSH access (management is SSH based, see `gateway/scripts/create-link.sh`
- Docker (required on Gateway, optional for client)
- Docker Compose (optional)

## Get started

**Point \*.selfhosted.pub (DNS A Record) to the IPv4 address of your Gateway host.**

1. Launch the Fractal Gateway service (nginx) (on Cloud VPS)
```
$ make setup
$ make gateway
```

A link is a dedicated WireGuard tunnel that has host name routed and SNI routed traffic to port 8080 and 8433 of the Caddy based `fractalnetworks/gateway-client:latest` container

SSH is used to communicate with the Gateway to create links.

2. From the machine you would like to expose to the public Internet, run the following command to generate a Docker Compose snippet that will expose the hypothetical Docker Compose service `nginx`, listening on port `80` to the world at `https://nginx.selfhosted.pub` 

```
$ make docker
$ make link GATEWAY=root@gateway.selfhosted.pub FQDN=nginx.selfhosted.pub EXPOSE=nginx:80
# add the following to any docker-compose.yml file for instant connectivity

  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.selfhosted.pub
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.161.127.102:49185
    cap_add:
      - NET_ADMIN
```

3. Adding the generated snippet to sample nginx `docker-compose.yml` file we get:
```
version: '3.9'
services:
  nginx:
    image: nginx:latest
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.selfhosted.pub
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.161.127.102:49185
    cap_add:
      - NET_ADMIN
```

Notice that it is **NOT necessary** to specify the following in the above docker-compose file:
```
ports:
 - 80:80
 - 443:443
```

All traffic(80/443) will be routed through your public Fractal Gateway.

4. Run `docker-compose up -d` and see that your local nginx container is accessible to the world with a valid TLS certificate (via Caddy Automatic HTTPS) at https://nginx.selfhosted.pub

## Limitations
- Currently only IPv4 is supported
- Raw UDP proxying is supported but currently untested & undocumented, see bottom of `gateway/link-entrypoint.sh` for more information.

## Support
Community support is available via our Matrix Channel https://matrix.to/#/#fractal:ether.ai
