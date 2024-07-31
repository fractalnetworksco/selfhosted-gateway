#!/bin/bash

# Generate a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx-selfsigned.key \
    -out nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=example.com"

# Move the files
mkdir -p /etc/nginx/ssl
mv nginx-selfsigned.key nginx-selfsigned.crt /etc/nginx/ssl/


# Start nginx
nginx -g 'daemon off;'
