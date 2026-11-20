FROM itzg/mc-proxy:java25@sha256:8d4b77b4aa7f2a6570c27d0c3fa537bd336fa09840ca74d890fbb144d8547dcd

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc