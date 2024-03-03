FROM alpine:latest

RUN apk add gettext openssh-client wireguard-tools;

COPY . /code

WORKDIR /code

# save created snippet variables to `/workdir/subdomain-domain-tld.env`
VOLUME /workdir

ENTRYPOINT ["/code/entrypoint.sh"]
