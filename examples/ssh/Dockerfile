FROM nginx:latest

COPY entrypoint.sh /entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["/entrypoint.sh"]
