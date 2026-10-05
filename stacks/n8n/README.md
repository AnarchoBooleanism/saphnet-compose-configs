## n8n
A workflow automation platform, with the flexibility of code and the speed of no-code.

When deploying, make sure to set these environment variables with your secrets:
- `N8N_RUNNER_TOKEN` - Shared secret to use between n8n and its runners, can be anything
- `POSTGRES_PASSWORD` - Password to use for PostgreSQL user
- `POSTGRES_NON_ROOT_PASSWORD` - Password to use for PostgreSQL non-root user (separate to `POSTGRES_PASSWORD`)
- `ENCRYPTION_KEY` - The encryption key for n8n and its workers. Generate this with `openssl rand -hex 32`
- `TAILSCALE_IP` - For certain services with exposed ports that bypass Traefik, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)
- `SMTP_FROM_EMAIL` - Email address to display as the from address
- `SMTP_SERVER_HOSTNAME` - Hostname of SMTP server
- `SMTP_SERVER_PORT` - Port of SMTP server
- `SMTP_USERNAME` - Username to use for SMTP server
- `SMTP_PASSWORD` - Password to use for SMTP server
- `TIMEZONE` - The name of a [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to use as the timezone (you can use the `TIMEZONE` Variable from Komodo)

Note that this configuration is intended to be able to scale up and work with other external workers, with its own PostgreSQL instance.