FROM itzg/mc-proxy:java25@sha256:e5ffb063f88cb0f49a25548d62b6a1c9957f6eaa33c1287256b53ac3dcb673a5

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc