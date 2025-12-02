# Pterodactyl
A server management panel for games, e.g. Minecraft

To create an account in the Pterodactyl panel (there will initially be no accounts), run this command in the Panel container: `php artisan p:user:make`

The two locations that will be used in our instance are `homelab` and `vps1`.

The main node, under the `homelab` location, will have an FQDN of `pterodactyl-node-main.int.saphnet.xyz` (this should be the domain that a reverse proxy with HTTPS support serves), use an SSL connection, be behind a proxy, and have a RAM allocation limit of 6144 MiB, 65536 MiB of disk space, and no overallocation, with the daemon port being 443, and the daemon SFTP port being 2022.

The vps1 node, under the `vps1` location, will have an FQDN of `pterodactyl-node-public.saphnet.xyz` (this should be the domain that a reverse proxy with HTTPS support serves; note that this should be only accessible within Tailscale), use an SSL connection, be behind a proxy, and have a RAM allocation limit of 512 MiB, 2048 MiB of disk space, and no overallocation, with the daemon port being 443, and the daemon SFTP port being 2022.

When setting up your node/Wing, remember to add this to your config.yml (ensure the subnet is different that of `ptero0`):
```yaml
docker:
  network:
    interfaces:
      v4:
        subnet: "10.55.230.0/24"
        gateway: 10.55.230.1
```

This is what an example config.yml for a node/Wing would look like:
```yaml
debug: false
uuid: my-uuid
token_id: mytokenid
token: mytoken
api:
  host: 0.0.0.0
  port: 443
  ssl:
    enabled: false
    cert: /etc/letsencrypt/live/pterodactyl-node-public.saphnet.xyz/fullchain.pem
    key: /etc/letsencrypt/live/pterodactyl-node-public.saphnet.xyz/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: 'https://pterodactyl.int.saphnet.xyz'
docker:
  network:
    interfaces:
      v4:
        subnet: "10.55.230.0/24"
        gateway: 10.55.230.1
```

When adding new SQL databases to the Pterodactyl panel, make sure to run this query on the SQL database before using it: `GRANT ALL PRIVILEGES ON *.* TO 'pterodactyl'@'%';`

For adding Velocity support to Pterodactyl, this egg is what you need: https://pterodactyleggs.com/egg/6735ff5d4924a4e9bbcbeac3

When allocating ports to nodes (and servers), be sure to allocate it to the IP address of `0.0.0.0`.

**REMINDER**: When creating servers, make sure the database and backup limits are above 0!
