FROM itzg/mc-proxy:java25@sha256:c764cfe4efaf2e9df13e2d71f1c6537a38ec19e12c52092f2c565ebd79019346

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc