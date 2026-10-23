FROM itzg/mc-proxy:java25@sha256:6a4a8819ec7665f5b03922d65304ece690148a34f8793bbf94d5515a34b00a4e

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc