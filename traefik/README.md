# Traefik
A cloud-native reverse proxy and load balancer

To run this, use this file and `base.yaml` together, so that `base.yaml`'s structure, with the default configuration settings, is merged with your instance-specific structure; an example would be with `docker compose -f base.yaml -f control-server.yaml up`

When deploying Traefik, make sure to set these environment variables with your secrets:
- `NAMECHEAP_API_USER` - Namecheap username to access Namecheap API with when generating SSL certificates with Let's Encrypt
- `NAMECHEAP_API_KEY` - Namecheap API key to access Namecheap API with when generating SSL certificates with Let's Encrypt. Note that, for this API key to work, the IP address used in the API requests should be whitelisted in the Namecheap portal. For more information on this, read https://www.namecheap.com/support/api/intro/
- `ACME_EMAIL` - Email address to give Let's Encrypt when generating SSL certificates (e.g. `homelab@saphnet.xyz`)
- `DASHBOARD_LOGIN` (optional, only if using dashboard) - The username and password hash to use for the dashboard, in the format of `username:passwordhash`. To generate a login, use htpasswd

If you wish to use a dashboard, make sure to add these to the labels section of the Traefik container:
```yaml
# Enable self‑routing
traefik.enable: "true"

# Dashboard router
traefik.http.routers.dashboard.rule: "Host(`traefik-host1.example.com`)" # Replace this with the domain you want to use for the dashboard
traefik.http.routers.dashboard.entrypoints: websecure
traefik.http.routers.dashboard.service: api@internal
traefik.http.routers.dashboard.tls: "true"
traefik.http.routers.dashboard.tls.certresolver: letsencrypt
traefik.http.routers.my-https-router.tls.options: modern-tls

# Basic‑auth middleware
traefik.http.middlewares.dashboard-auth.basicauth.users: "${DASHBOARD_LOGIN}"
traefik.http.routers.dashboard.middlewares: dashboard-auth@docker
```

TODO: Add section on integrating services with Traefik