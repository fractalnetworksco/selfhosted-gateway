FROM alpine:latest

RUN apk add gettext openssh-client wireguard-tools python3;
COPY . /code
WORKDIR /code/scripts
ENTRYPOINT ["/code/scripts/entrypoint.sh"]
