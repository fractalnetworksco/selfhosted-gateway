# Proxying SSH connections

The files in this directory illustrate how the selfhosted-gateway can be used to proxy
ssh connections to remote hosts without publicly routable IP addresses.

## Start local ssh server
```
docker compose up -d
```

## Connect to local ssh server via the Gateway
```
ssh -o "ProxyCommand=openssl s_client -connect %h:%p -quiet" -p 443 root@gateway.host -o ServerAliveInterval=30 -o ServerAliveCountMax=120
root@gateway.host's password:
```

Note that ServerAliveInterval and ServerAliveCountMax are required to maintain a stable connection.

Try lowering the local link container's `MTU` environment variable if you experience connections getting stuck.