#!/bin/bash

# Define where to save the generated SSL certificate and private key
SSL_CERT="/etc/nginx/server.crt"
SSL_KEY="/etc/nginx/server.key"

# Generate a Private Key and a Self-Signed Certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_KEY" -out "$SSL_CERT" \
    -subj "/C=US/ST=YourState/L=YourCity/O=YourOrganization/OU=YourDepartment/CN=yourdomain.com"

nginx -g "daemon off;"
