FROM alpine:latest
RUN apk add openssh-server bash docker-cli curl
RUN ssh-keygen -A

COPY gateway-sim-key.pub /root/.ssh/authorized_keys
# set UseDNS no to avoid slow ssh login
RUN echo "UseDNS no" >> /etc/ssh/sshd_config

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
