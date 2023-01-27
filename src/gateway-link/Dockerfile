FROM alpine:latest

ARG RELEASE_TAG

ADD entrypoint.sh /usr/bin/entrypoint.sh

RUN apk add iptables socat wireguard-tools

ENV NOTEWORTHY_ENV $RELEASE_TAG
ENV LINK_MTU=1380

ENTRYPOINT [ "entrypoint.sh" ]
