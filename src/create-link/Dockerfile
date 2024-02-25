FROM alpine:latest

RUN apk add gettext openssh-client wireguard-tools;

COPY . /code

WORKDIR /code

ENTRYPOINT ["/code/entrypoint.sh"]
