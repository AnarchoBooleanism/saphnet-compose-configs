FROM itzg/mc-proxy:java25@sha256:ad9da66526ad300429f0992b0b10724649f852ae19a66f58c447f484747fb469

# Create welcome messages
ENV ENV="/etc/profile"
COPY welcome.sh /etc/profile.d/welcome.sh
# Since bash won't read /etc/profile
RUN cat /etc/profile.d/welcome.sh >> /etc/bash.bashrc