FROM caddy:2.7

ARG RELEASE_TAG

RUN apk add gettext wireguard-tools socat

COPY entrypoint.sh /usr/bin/entrypoint.sh

COPY Caddyfile.template /etc/Caddyfile.template

ENV NOTEWORTHY_ENV $RELEASE_TAG
ENV LINK_MTU=1380

# preserve certs and keys
VOLUME /data

ENTRYPOINT [ "entrypoint.sh" ]
