FROM itzg/mc-proxy:java25@sha256:acb44a5cbe1c32896cf4671d8cf5c5252f57831eb779eb0a924dc663f653b34e

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc