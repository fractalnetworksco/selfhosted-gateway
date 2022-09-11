docker run --network gateway  -p 80:80 -p 443:443 -e GATEWAY_DOMAIN=selfhosted.pub -e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx -it fractalnetworks/gateway:latest
