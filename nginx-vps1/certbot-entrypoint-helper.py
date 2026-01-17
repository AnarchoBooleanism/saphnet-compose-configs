# Helper script for Certbot entrypoint
import os, subprocess

# Create /namecheap.ini
with open("/namecheap.ini", "a") as file:
    print(f"Namecheap username is {os.environ["DNS_NAMECHEAP_USERNAME"]}")
    file.write(f"dns_namecheap_username={os.environ["DNS_NAMECHEAP_USERNAME"]}\n")
    print(f"Namecheap API key is {os.environ["DNS_NAMECHEAP_API_KEY"]}")
    file.write(f"dns_namecheap_api_key={os.environ["DNS_NAMECHEAP_API_KEY"]}\n")

# Check that all certificates for all domains exist, if not then create them
# List of groups of domains, grouped by certificate
domain_groups = [domain_list.split(",") for domain_list in os.environ["CERTBOT_DOMAINS"].split(" ")]
missing_domain_groups = []

for domain_group in domain_groups:
    print("Checking domains " + ", ".join(domain_group) + "...")
    if not os.path.exists(f"/etc/letsencrypt/live/{domain_group[0]}/fullchain.pem"):
        missing_domain_groups.append(domain_group)
        print(f"Certificate file does not exist for first domain {domain_group[0]}...")

# Since certificates only work for one root domain
for domain_group in missing_domain_groups:
    print("Running Certbot to create certificates for " + \
          ", ".join(domain_group) + " " \
          f"(the certificate's name will be {domain_group[0]})"
    )
    command_arguments = [
        "certbot", "certonly",
        "-a", "dns-namecheap",
        "--dns-namecheap-credentials=/namecheap.ini",
        "--agree-tos", "--non-interactive", "-vv",
        "--no-eff-email", "--email", os.environ["CERTBOT_EMAIL"],
        "--domain", ",".join(domain_group)
    ]
    print(f"Running command \"{' '.join(command_arguments)}\"...")
    command_result = subprocess.call(command_arguments)
    print(f"Certbot exited with code {command_result}.")

if not missing_domain_groups:
    print("No domain groups without certificates exist. Continuing...")
