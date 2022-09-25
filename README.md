# Self-hosted Gateway

Lighweight, no-code implementation of the Fractal Gateway RPoVPN.

Combines Docker, Nginx and WireGuard to enable self-hosted connectivity to your self-hosted applications.

Inspired by: http://widgetsandshit.com/teddziuba/2010/10/taco-bell-programming.html

And: https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2

Similar products:
- Cloudflare Argo Tunnels
- ngrok
- Inlets
- Pagekite
- Packetriot
- frp (Fast Reverse Proxy)
- Tailscale (roadmap)
- Zerotier (roadmap)

## Architectural Overview
![selfhosted-gateway](https://user-images.githubusercontent.com/109041/192158916-a2cc9f80-9c8d-455f-80d7-fb51e3c275a7.png)

## Reverse Proxy-over-VPN (RPoVPN)
1. **RPoVPN is a common strategy for self-hosting publicly accessible services from home, providing alternative to or workaround for:**
  - Opening ports on your local Internet router or firewall
  - Using a dynamic DNS provider due to a lack of a static IP
  - Self-hosting behind double-NAT or via an ISP that does CGNAT (Starlink, T-mobile Home Internet)

2. **Using RPoVPN is ideal for self-hosting from both a network security and privacy perspective:**
  - RPoVPN eliminates the need to expose your public IP address to the world.
  - Fractal Gateway RPoVPN uses advanced network isolation capabilities of the Linux kernel (network namespaces) to keep self-hosted services isolated from your home network and your other local / self-hosted services.

## Terminology
- `Link` - We use the termn "Link" to describe the dedicated WireGuard tunnel between your local device and the `Link Container` running on the Gateway

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

Notice it is **NOT necessary** to specify the following in the above docker-compose file:
```
ports:
 - 80:80
 - 443:443
```

All traffic to the local container is routed through the RPoVPN Gateway.

4. Run `docker-compose up -d` and see that your local nginx container is accessible to the world with a valid TLS certificate (via Caddy Automatic HTTPS) at https://nginx.selfhosted.pub

## Show all links running on a Gateway
```
$ docker ps
```

## Limitations
- Currently only IPv4 is supported
- Raw UDP proxying is supported but currently untested & undocumented, see bottom of `gateway/link-entrypoint.sh` for more information.

## FAQ
- How is this better than setting up nginx and WireGuard myself on a VPS?

We built this project to make self-hosting more accessible and reproducible. This project is employes a "ZeroTrust" network architechture (see architectural diagram above). Each application gets its own dedicated WireGuard tunnel that isolates it from the underyling host and all other applications. This capability is provided by Docker Compose's networking model (each project gets a private network).

Further, adding additional self-hosted applications requires no manual configuration changes. Just run the `make link GATEWAY=...` command to get connectivity setup for a new application, this is very useful for someone who self-hosts many different services.


## Support
Community support is available via our Matrix Channel https://matrix.to/#/#fractal:ether.ai
