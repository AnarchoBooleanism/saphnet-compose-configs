#!/bin/sh
# Main entrypoint
set -eu

trap "exit" TERM

# Run Python helper script, for more functionality
python -u /certbot-entrypoint-helper.py

# Renewal loop
while true; do
  certbot renew -vv
  sleep 12h &
  wait $!
done