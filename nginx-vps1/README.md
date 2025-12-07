## nginx-vps1
The configuration for the reverse proxy running on vps1, using Nginx and Anubis.

When creating a new public-facing domain host, make sure to set up an Anubis instance for it, linking to where the back-end server is, with these environment variables set: `COOKIE_DOMAIN`, `PUBLIC_URL`, `REDIRECT_DOMAINS`, `TARGET`, and everything in `anubis-environment`. As well, make sure that an Nginx config block is set for this domain, with the upstream server for Nginx being the Anubis instance, and that Certbot creates a certificate for this domain.