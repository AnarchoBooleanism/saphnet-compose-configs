#!/bin/sh
set -eu

trap "exit" TERM

# Create /namecheap.ini
cat > /namecheap.ini <<EOF
dns_namecheap_username=$DNS_NAMECHEAP_USERNAME
dns_namecheap_api_key=$DNS_NAMECHEAP_API_KEY
EOF

# First-time certificate
if [ ! -f "/etc/lets_encrypt/live/$CERTBOT_DOMAIN/fullchain.pem" ]; then
  certbot certonly \
    -a dns-namecheap \
    --dns-namecheap-credentials=/namecheap.ini \
    --agree-tos --non-interactive -vv \
    --no-eff-email \
    --email "$CERTBOT_EMAIL" \
    --domain "$CERTBOT_DOMAIN"
fi

# Renewal loop
while true; do
  certbot renew -vv
  sleep 12h &
  wait $!
done