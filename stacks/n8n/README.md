## n8n
A workflow automation platform, with the flexibility of code and the speed of no-code.

When deploying, make sure to set these environment variables with your secrets:
- `N8N_RUNNER_TOKEN` - Shared secret to use between n8n and its runners, can be anything
- `MAIL_PASSWORD` - Password to use for SMTP password
- `POSTGRES_PASSWORD` - Password to use for PostgreSQL user
- `POSTGRES_NON_ROOT_PASSWORD` - Password to use for PostgreSQL non-root user (separate to `POSTGRES_PASSWORD`)
- `ENCRYPTION_KEY` - The encryption key for n8n and its workers. Generate this with `openssl rand -hex 32`
- `TAILSCALE_IP` - For certain services with exposed ports that bypass Traefik, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)

Note that this configuration is intended to be able to scale up and work with other external workers, with its own PostgreSQL instance.