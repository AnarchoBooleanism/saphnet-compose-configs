# Helper script for Certbot entrypoint
import os, subprocess
from collections import defaultdict

# Create /namecheap.ini
with open("/namecheap.ini", "a") as file:
    print(f"Namecheap username is {os.environ["DNS_NAMECHEAP_USERNAME"]}")
    file.write(f"dns_namecheap_username={os.environ["DNS_NAMECHEAP_USERNAME"]}\n")
    print(f"Namecheap API key is {os.environ["DNS_NAMECHEAP_API_KEY"]}")
    file.write(f"dns_namecheap_api_key={os.environ["DNS_NAMECHEAP_API_KEY"]}\n")

# Check that all certificates for all domains exist, if not then create them
domain_array = os.environ["CERTBOT_DOMAINS"].split(" ")
missing_domains = []

print("Checking domains " + ",".join(domain_array))
for domain in domain_array:
    if not os.path.exists(f"/etc/letsencrypt/live/{domain}/fullchain.pem"):
        missing_domains.append(domain)

# Since certificates only work for one root domain
for domain in missing_domains:
    print(f"Running Certbot to create certificates for \"{domain}\"...")
    subprocess.call([
        "certbot", "certonly",
        "-a", "dns-namecheap",
        "--dns-namecheap-credentials=/namecheap.ini",
        "--agree-tos", "--non-interactive", "-vv",
        "--no-eff-email", "--email", os.environ["CERTBOT_EMAIL"],
        "--domain", domain
    ])

if not missing_domains:
    print("No domains without certificates exist. Continuing...")
