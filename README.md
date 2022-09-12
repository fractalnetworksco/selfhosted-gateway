# Self-hosted Fractal Gateway

This is a lighweight implementation of the Fractal Gateway RPoVPN.

It combines Docker, Nginx and WireGuard in a novel way to enable self-hosted connectivity to your self-hosted applications.

Similar products:
- Cloudflare Argo Tunnels
- ngrok
- Inlets
- Pagekite
- Tailscale
- Zerotier

## Reverse Proxy-over-VPN (RPoVPN)
1. **RPoVPN is a common strategy for self-hosting private services from home while elimating the need for complex local network configuration changes such as:**
  - Opening ports on your local Internet router or firewall
  - using a dynamic DNS provider due to the lack of a static IP

2. **Using Fractal Gateway RPoVPN is ideal for self-hosting from both a network security and privacy perspective:**
  - Fractal Gateway RPoVPN eliminates the need to expose your home IP address to the public.
  - Fractal Gateway RPoVPN uses advanced network isolation capabilities of Docker and the Linux kernel to keep self-hosted services isolated from your home network and other self-hosted services.

## Dependencies
- Publicly accessible host with open tcp ports 80/443 and udp port range `/proc/sys/net/ipv4/ip_local_port_range`
- SSH access (gateway is managed via SSH, see `gateway/scripts/create-link.sh`
- Docker (required on Gateway, optional for client)
- Docker Compose (optional)

## Example Usage
Generate a Docker Compose snippet to expose an `nginx` container to the world at `nginx.selfhosted.pub` 
```
$ ./scripts/create-link.sh root@gateway.selfhosted.pub nginx.selfhosted.pub nginx:80
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
Add the generated snippet to a `docker-compose.yml` file.

Here's the complete file:
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
Run `docker-compose up -d` then visit https://nginx.selfhosted.pub

## Support
Community support is available via our Matrix Channel https://matrix.to/#/#fractal:ether.ai
