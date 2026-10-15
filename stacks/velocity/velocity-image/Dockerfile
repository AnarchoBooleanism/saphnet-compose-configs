FROM itzg/mc-proxy:java25@sha256:91948f607fb084c061964e3a8f796d36ce3c1e284505f1e823ef222d93abceba

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc