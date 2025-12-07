# Helper script for Certbot entrypoint
import os, subprocess

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

if missing_domains:
    print("Running Certbot to create certificates for " + ",".join(missing_domains) + "...")
    subprocess.call([
        "certbot", "certonly",
        "-a", "dns-namecheap",
        "--dns-namecheap-credentials=/namecheap.ini",
        "--agree-tos", "--non-interactive", "-vv",
        "--no-eff-email", "--email", os.environ["CERTBOT_EMAIL"],
        "--domains", ",".join(missing_domains)
    ])
else:
    print("No domains without certificates exist. Continuing...")
