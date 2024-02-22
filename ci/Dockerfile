FROM alpine:latest
RUN apk add openssh-server
RUN ssh-keygen -A

COPY gateway-sim-key.pub /root/.ssh/authorized_keys

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]

