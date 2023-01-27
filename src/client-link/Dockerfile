FROM alpine:latest

ARG RELEASE_TAG

RUN apk add gettext wireguard-tools caddy socat

COPY client-entrypoint.sh /usr/bin/client-entrypoint.sh

COPY Caddyfile.template /etc/Caddyfile.template

ENV NOTEWORTHY_ENV $RELEASE_TAG
ENV LINK_MTU=1380

ENTRYPOINT [ "entrypoint.sh" ]
