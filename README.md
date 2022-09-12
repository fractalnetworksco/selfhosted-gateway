# selfhosted-gateway

This is a simplified implementation of the Fractal Gateway RPoVPN. It combines Docker, Nginx and WireGuard in a novel way to enable painless self-hosting behind a cloud based gateway.

## Dependencies
- Public accessible web server
- SSH access (managment is done via ssh see `scripts/_create-link.sh`
- Docker

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
Now run `docker-compose up -d` then visit https://nginx.selfhosted.pub
