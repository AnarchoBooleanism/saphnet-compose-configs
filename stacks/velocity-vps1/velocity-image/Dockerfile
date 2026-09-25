FROM itzg/mc-proxy:java25@sha256:d06e5af9a545f90421202e6eebab04674068ed9a057ce61de5a4f83bca8f4b54

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc