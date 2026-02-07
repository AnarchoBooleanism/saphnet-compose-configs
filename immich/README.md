## immich
A self-hosted photo and video management solution

NOTE: Relies on Traefik setup.

When deploying, make sure to set these environment variables with your secrets:
- `DB_PASSWORD` - Password to use for PostgreSQL instance
- `REDIS_PASSWORD` - Password to use for Redis instance
- `TAILSCALE_IP` - For certain services with exposed ports that bypass Traefik, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)

This setup is designed to work with an NFS server, for storing Immich's data (not including the PostgreSQL database), including file uploads.

As well, this setup is designed to be able to scale up and work with other services and instances, with the PostgreSQL and Redis instances being externally available via the respective ports.