# Self-hosted Gateway

This project automates the provisioning of WireGuard reverse proxy tunnels for self-hosting with `docker compose`. It was designed to provide a fully self-hosted alternative to Cloudflare Tunnels or Tailscale Funnel. Best of all there's no code or APIs. Just an ultra generic nginx config and a short bash script.


It works by generating a docker compose snippet that you can add to your existing docker compose files. The `EXPOSED` docker compose service will then be publically accessible.


Full `docker-compose.yml` example:
```
version: '3.9'
services:
  nginx:
    image: nginx:latest
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.mydomain.com
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.125.122.12:49185 
    cap_add:
      - NET_ADMIN
```
The above example deploys a publically accessible nginx server at https://nginx.mydomain.com -- TLS certs are provisioned by Caddy's Automatic HTTPS feature via Let's Encrypt.

## Background

Reverse Proxy-over-VPN (RPoVPN)

1. **RPoVPN is a common strategy for self-hosting publicly accessible services from home, providing fully self-managed alternatives to / workarounds for:**
  - Proprietary connectivy service providers such as Cloudflare, Tailscale or ngrok
  - The need to open ports on your home router or firewall
  - The need to use a dynamic DNS provider due to a lack of a static IP
  - Self-hosting behind double-NAT or via an ISP that does CGNAT (Starlink, T-mobile Home Internet)

2. **Using RPoVPN is ideal for self-hosting from both a network security and privacy perspective:**
  - RPoVPN eliminates the need to expose your home public IP address to the world.
  - Selfhosted gateway uses advanced network isolation capabilities of Docker (via Linux network namespaces) to isolate your self-hosted services from your home network and your other docker self-hosted services.

## Terminology
- `Link` - A dedicated WireGuard tunnel between a local container (client) and the remote container running on the Gateway through which Reverse Proxy traffic is routed. A link is comprised of 2 pieces, the local or client link and the gateway or remote link.

## Dependencies
- A custom apex domain for example **mydomain.com** 
- A Linux host Gateway, typically a cloud VPS (Hetzner, Digital Ocean, etc) with open ports 80/443 (http(s)) and udp port range `/proc/sys/net/ipv4/ip_local_port_range` exposed to the world
- SSH is used for link provisioning, see `gateway/scripts/create-link.sh`
- Docker and Docker Compose 

## Get started

**Point \*.mydomain.com (DNS A Record) to the IPv4 & IPv6 address of your VPS Gateway host.**

1. Launch the Fractal Gateway service (nginx) (on Gateway)
```
$ make setup
$ make gateway
```


2. From the local docker service you would like to expose to the public Internet, run the following command to generate a docker compose snippet that will expose the docker compose service `nginx`, listening on internal port `80` to the world at `https://nginx.mydomain.com` 

```
$ make docker
$ make link GATEWAY=root@gateway.mydomain.com FQDN=nginx.mydomain.com EXPOSE=nginx:80

  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.mydomain.com
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.161.127.102:49185
    cap_add:
      - NET_ADMIN
```

3. Adding the generated snippet to your `docker-compose.yml` file we get:
```
version: '3.9'
services:
  nginx:
    image: nginx:latest
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.mydomain.com
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.161.127.102:49185
    cap_add:
      - NET_ADMIN
```

If you would still like to access service from your local network you will need to expose ports on your Docker host as you would traditionally, but this is no longer necessary:
```
ports:
 - 80:80
 - 443:443
```

Traffic from the public Internet will be routed through the RPoVPN Selfhosted Gateway.

4. Run `docker-compose up -d` and see that your local nginx container is accessible to the world with a valid TLS certificate (via Caddy Automatic HTTPS) at https://nginx.mydomain.com

## Split DNS without SSL Termination

In the event you already have a reverse proxy which performs SSL termination for your apps/services you can enable `FORWARD_ONLY` mode. Suppose you are using Traefik for SSL termination:

1. On your local LAN you will resolve \*.sub.mydomain.com to your local Traefik IP
2. On your external DNS for your domain you will resolve \*.sub.mydomain.com to the IP of your VPS
3. In your compose file add an additional two variables: `EXPOSE_HTTPS` and `FORWARD_ONLY`

```yaml
version: '3.9'
services:
  app:
    image: traefik:latest
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: sub.mydomain.com
      EXPOSE: app:80
      EXPOSE_HTTPS: app:443
      FORWARD_ONLY: "True"
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 5.161.127.102:49185
    cap_add:
      - NET_ADMIN
```
You will see logs from the link container indicating it is in forward only mode:
```
traefikv2_link.1.qvijxtwiu0wb@docker01    | + socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:app:443,reuseaddr
traefikv2_link.1.qvijxtwiu0wb@docker01    | + socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:app:80,reuseaddr
```

## Show all links running on a Gateway
```
$ docker ps
```

## Limitations
- Currently only IPv4 is supported
- Raw UDP proxying is supported but is currently untested & undocumented, see bottom of `gateway/link-entrypoint.sh`.

## FAQ
- How is this better than setting up nginx and WireGuard myself on a VPS?

The goal of this project is to self-hosting more accessible and reproducible. This selfhosted-gateway leverages a "ZeroTrust" network architecture (see diagram above). Each "Link" provides a dedicated WireGuard tunnel that is isolated from other containers and the underlying. This isolation is provided by Docker Compose's creation of a private Docker network for each compose file (project).


## Support
Community support is available via our Matrix Channel https://matrix.to/#/#fractal:ether.ai
