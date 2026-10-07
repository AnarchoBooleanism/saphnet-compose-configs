FROM itzg/mc-proxy:java25@sha256:6b6dedbc239368b2d9b96bf438d6f222611b09019420fce3d55284fc2fa20c97

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc