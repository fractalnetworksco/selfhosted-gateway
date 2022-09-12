FROM alpine:latest

COPY . /code
RUN apk add gettext openssh-client wireguard-tools python3;
WORKDIR /code/scripts
ENTRYPOINT ["/code/scripts/create-link.sh"]

