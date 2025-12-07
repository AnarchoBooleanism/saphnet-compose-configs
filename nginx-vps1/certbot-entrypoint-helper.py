# Helper script for Certbot entrypoint
import os, subprocess

# Create /namecheap.ini
with open("/namecheap.ini", "a") as file:
    file.write(f"dns_namecheap_username={os.environ["DNS_NAMECHEAP_USERNAME"]}")
    file.write(f"dns_namecheap_api_key={os.environ["DNS_NAMECHEAP_API_KEY"]}")

# Check that all certificates for all domains exist, if not then create them
domain_array = os.environ["CERTBOT_DOMAINS"].split(" ")
missing_domains = []

for domain in domain_array:
    if not os.path.exists(f"/etc/lets_encrypt/live/{domain}/fullchain.pem"):
        missing_domains.append(domain)

if missing_domains:
    subprocess.call([
        "certbot", "certonly",
        "-a", "dns-name-cheap",
        "--agree-tos", "--non-interactive", "-vv",
        "--no-eff-email", "--email", os.environ["CERTBOT_EMAIL"],
        "--domains", ",".join(missing_domains)
    ])
