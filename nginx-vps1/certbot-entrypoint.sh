#!/bin/bash
set -eu

trap "exit" TERM

domain_array=($CERTBOT_DOMAINS)

# Create /namecheap.ini
cat > /namecheap.ini <<EOF
dns_namecheap_username=$DNS_NAMECHEAP_USERNAME
dns_namecheap_api_key=$DNS_NAMECHEAP_API_KEY
EOF

# Check that all certificates for all domains exist, if not then create them
missing_domains=()

for domain_name in "${domain_array[@]}";
do
  if [ ! -f "/etc/lets_encrypt/live/$domain_name/fullchain.pem" ]; then
    missing_domains+=(domain_name)
  fi
done

# If array not empty
if [ ! ${#missing_domains[@]} -eq 0 ]; then
  certbot certonly \
    -a dns-namecheap \
    --dns-namecheap-credentials=/namecheap.ini \
    --agree-tos --non-interactive -vv \
    --no-eff-email \
    --email "$CERTBOT_EMAIL" \
    --domains "$(IFS=, ; echo "${missing_domains[*]}")"
fi

# Renewal loop
while true; do
  certbot renew -vv
  sleep 12h &
  wait $!
done