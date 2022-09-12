# selfhosted-gateway

This is a simplified implementation of the Fractal Gateway RPoVPN. It combines Docker, Nginx and WireGuard in a novel way to enable painless self-hosting behind a cloud based gateway.

```
$ ./scripts/create-link.sh root@gateway.selfhosted.pub mo.selfhosted.pub nginx:80
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: mo.selfhosted.pub
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: UI4uBAyv/7Fff435o3MSsZ+ZA2LnNv065EdlMxyOIFg=
      GATEWAY_LINK_WG_PUBKEY: 3JDmEtLAvnRgMAJub0wdHsmo2V6j+zm5abispjLlmno=
      GATEWAY_ENDPOINT: 5.161.127.102:49183
    cap_add:
      - NET_ADMIN
```
