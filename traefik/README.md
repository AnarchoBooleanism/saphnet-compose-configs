## Traefik
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
traefik.http.routers.dashboard.rule: "Host(`host1.example.com`)" # Replace this with the domain you want to use for the dashboard
traefik.http.routers.dashboard.entrypoints: websecure
traefik.http.routers.dashboard.service: api@internal
traefik.http.routers.dashboard.tls: "true"
traefik.http.routers.dashboard.tls.certresolver: letsencrypt
traefik.http.routers.dashboard.tls.domains[0].main: "host1.example.com" # Reflecting the style used by existing docker-hosts.
traefik.http.routers.dashboard.tls.domains[0].sans: "*.host1.example.com"

# Basic‑auth middleware
traefik.http.middlewares.dashboard-auth.basicauth.users: "${DASHBOARD_LOGIN}"
traefik.http.routers.dashboard.middlewares: dashboard-auth@docker
```

### Integrating Docker-based services with Traefik
When integrating services running in Docker containers on the same host as Traefik, use labels to identify the service and set certain settings so that Traefik can automatically discover the service and publish it with the right configuration. As well, Traefik is set in saphnet-compose-configs to connect to containers through the `web_bridge` network, so be sure to add your containers to this network.

Here is an example of how you would set this up in a Docker Compose file:
```yaml
services:
  jellyfin:
    image: ... # Truncating here
    labels:
      traefik.enable: true
      traefik.http.routers.jellyfin.rule: Host(`jellyfin.media.int.saphnet.xyz`)
      traefik.http.routers.jellyfin.entrypoints: websecure
      traefik.http.routers.jellyfin.tls: true
      traefik.http.routers.jellyfin.tls.certresolver: letsencrypt
      ## HTTP Service
      traefik.http.routers.jellyfin.service: jellyfin-svc
      traefik.http.services.jellyfin-svc.loadBalancer.server.port: "8096"
    networks:
      - web_bridge # Traefik, in this instance, connects to services via the web_bridge network, so we need to be reachable through it
    ... # Again, truncating
    restart: unless-stopped
```

We start with `traefik.enable`: this label signals to Traefik that this Compose service should be taken into account and configured for. After that, we have the rules under `traefik.http.routers`, for setting up the `jellyfin` HTTP router: `rule` determines the host/domain (e.g. `jellyfin.media.int.saphnet.xyz`) whose traffic is directed to/from the router, `entrypoints` determines the Traefik entrypoint, the port (and interface) that Traefik listens to, that this router is connected to (`websecure`, in this case, is just the entrypoint for HTTPS, via port 443), `tls` sets whether we use TLS for security, and `tls.certresolver` allows the HTTP router to use the configured Let's Encrypt-based certificate resolver to generate SSL certificates, so that browsers will not complain about insecure connections via the default self-signed certificate. With the HTTP router set, an HTTP service is configured so that traffic to/from the router can make it to its destination point, the Compose service: the service of the `jellyfin` router is set to `jellyfin-svc`, and `jellyfin-svc` is provided with the port of the upstream server, 8096, allowing traffic to be directed to port 8096 of the `jellyfin` Compose service. Finally, the Compose service is connected to the `web_bridge` network so that Traefik can directly connect to it.

A generic example would look like this:
```yaml
services:
  example:
    image: ... # Truncating here
    labels:
      traefik.enable: true
      traefik.http.routers.EXAMPLENAME.rule: Host(`EXAMPLEDOMAIN.EXAMPLE.COM`)
      traefik.http.routers.EXAMPLENAME.entrypoints: websecure
      traefik.http.routers.EXAMPLENAME.tls: true
      traefik.http.routers.EXAMPLENAME.tls.certresolver: letsencrypt
      ## HTTP Service
      traefik.http.routers.EXAMPLENAME.service: EXAMPLESERVICE
      traefik.http.services.EXAMPLESERVICE.loadBalancer.server.port: "8096"
    networks:
      - web_bridge # Traefik, in this instance, connects to containers via the web_bridge network, so we need to be reachable through it
    ... # Again, truncating
    restart: unless-stopped
```

Note that the HTTP router and service names can be anything, but they must remain consistent within the labels of the same Compose service.

### Redirecting domains
If you want to have Traefik be able to listen to certain hostnames (e.g. `media.int.saphnet.xyz`) and redirect traffic from them to another hostname (e.g. `jellyfin.media.int.saphnet.xyz`), you simply need to add a router for the origin domain/hostname, but instead of an upstream HTTP service, it simply gets handled by a regex-based redirector as HTTP middleware; this just needs to be done through labels for your containers.

Here is an example of how you would set this up for a Docker Compose service:
```yaml
services:
  jellyfin:
    labels:
      ... # We can have a router for the target service here too, which we are skipping for now
      # Redirect media.int.saphnet.xyz to jellyfun.media.int.saphnet.xyz
      traefik.http.routers.media.rule: "Host(`media.int.saphnet.xyz`)"
      traefik.http.routers.media.middlewares: "media-redirectregex"
      traefik.http.middlewares.media-redirectregex.redirectregex.regex: "^https://media\\.int\\.saphnet\\.xyz/(.*)"
      traefik.http.middlewares.media-redirectregex.redirectregex.replacement: "https://jellyfin.media.int.saphnet.xyz/$${1}"
    ... # Omitting for brevity
```

This creates an HTTP router targeting `media.int.saphnet.xyz`, which then has the `media-redirectregex` middleware assigned to it. The `media-redirectregex` middleware is configured as the `redirectregex` type, replacing `https://media.int.saphnet.xyz/` in requests with `https://jellyfin.media.int.saphnet.xyz/`, keeping the path intact, and then sending the correct redirect response to the client. Note that in the regex, all dots need to be escaped with `\\`, and `(.*)` is set at the end so that we can match this hostname for any path; in the replacement label, we make sure to set `$${1}` at the end for the path to be appended to the desired redirect target. Furthermore, note that you will still need to configure HTTPS/TLS for this HTTP router, like any other.

### Setting wildcard/multi-domain certificates
If you want to generate only specific certificates that are shared across multiple hostnames/HTTP routers, make sure to explicitly set this in the label of your Compose services; Traefik will only generate certificates for sets of domains that do not exist yet, reusing existing certificates if they apply to new routers.

This is what it would look like:
```yaml
services:
  jellyfin:
    labels:
      ...
      traefik.http.routers.jellyfin.tls.domains[0].main: media.int.saphnet.xyz
      traefik.http.routers.jellyfin.tls.domains[0].sans: "*.media.int.saphnet.xyz"
    ... # Omitting for brevity
```

This sets certificate #0 (note that you can have multiple certificates for the same HTTP router, noted by the number for the array) with the main domain (`media.int.saphnet.xyz` in this case), as well as a comma-separated list of Subject Alternative Names (SANs). This allows you to share one certificate across multiple different HTTP routers targeting disparate domain names.

Keep in mind, however, that the main domain and list of SANs should be kept consistent between Compose services that are intended to share the certificate, so that Traefik does not generate another one for each Compose service that has it written differently.