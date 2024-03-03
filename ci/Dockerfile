FROM alpine:latest
RUN apk add openssh-server bash docker-cli curl
RUN ssh-keygen -A

COPY gateway-sim-key.pub /root/.ssh/authorized_keys

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
