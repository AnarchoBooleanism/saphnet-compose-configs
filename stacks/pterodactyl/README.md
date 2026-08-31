## Pterodactyl
A server management panel for games, e.g. Minecraft.

To create an account in the Pterodactyl panel (there will initially be no accounts), run this command in the Panel container: `php artisan p:user:make`

The two locations that will be used in our instance are `homelab` and `vps1`.

The main node, under the `homelab` location, will have an FQDN of `pterodactyl-node-main.int.saphnet.xyz` (this should be the domain that a reverse proxy with HTTPS support serves), use an SSL connection, be behind a proxy, and have a RAM allocation limit of 6144 MiB, 65536 MiB of disk space, and no overallocation, with the daemon port being 443, and the daemon SFTP port being 2022.

When adding new SQL databases to the Pterodactyl panel, make sure to run this query on the SQL database before using it: `GRANT ALL PRIVILEGES ON *.* TO 'pterodactyl'@'%';`

For adding Velocity support to Pterodactyl, this egg is what you need: https://pterodactyleggs.com/egg/6735ff5d4924a4e9bbcbeac3

When allocating ports to nodes (and servers), be sure to allocate it to the IP address of `0.0.0.0`.

For servers involving heavy use, make sure to use Aikar's flags in your set of startup flags; make sure the container has no set memory limit. This is what it looks like, generated with [this tool provided by Paper](https://docs.papermc.io/misc/tools/start-script-gen/):
```
java -Xms4096M -Xmx4096M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dterminal.jline=false -Dterminal.ansi=true -jar {{SERVER_JARFILE}}
```
Note that memory usage is set in the `-Xms####M` and `-Xmx####M`, which respectively set a minimum and a maximum limit for RAM allocation. These generally should be set to the same value.

**REMINDER**: When creating servers, make sure the database and backup limits are above 0!

When using reverse proxies (e.g. Velocity) on the same host as the upstream server, make sure to use the server UUID (in the context of Pterodactyl, Docker DNS will resolve this) of the Docker container (of the upstream server) in the context of the internal Pterodactyl bridge, as connecting to the host IP will not work (due to firewall issues, most likely).

### On config.yml
When setting up your node/Wing, remember to add this to your config.yml (ensure the subnet is different to that of `ptero0`):
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
  backups:
    rustic:
      binary_path: rustic
      repository_version: 2
      tree_pack_size_mb: 4
      data_pack_size_mb: 32
      local: { enabled: true, repository_path: /var/lib/elytra/rustic-repos, use_cold_storage: false, hot_repository_path: '' }
      s3: { enabled: true, endpoint: 'https://s3.nas1.int.saphnet.xyz', region: garage, bucket: pterodactyl-backups, use_cold_storage: false, hot_bucket: '', cold_storage_class: GLACIER, force_path_style: true, disable_ssl: false, ca_cert_path: '' }
  machine_id:
    enabled: false
allowed_mounts: []
remote: 'https://pterodactyl.int.saphnet.xyz'
allowed_origins:
  - 'https://pterodactyl.int.saphnet.xyz'
docker:
  network:
    interfaces:
      v4:
        subnet: "10.55.230.0/24"
        gateway: 10.55.230.1
```

In general, however, this should be created by an init service that uses a template file that looks like the above code, fills it in with the necessary token-related values, and writes it to a file that the Pterodactyl Wing will use as its `config.yml` file. There already exists a `config.yml.template` file in the `wing/init-config` subdirectory that has virtually all of the options above, sans the token-related values, which the init service can use. Here is an example of such a service:
```yaml
services:
  ... # Omitting for brevity
  init-config:
    build: ./init-config
    volumes:
      - ./init-config/config.yml.template:/config.yml.template
      - wings-config:/wings-config
    environment:
      PTERODACTYL_TOKEN_ID: "${PTERODACTYL_TOKEN_ID}"
      PTERODACTYL_TOKEN: "${PTERODACTYL_TOKEN}"
    entrypoint:
      - /bin/sh
      - -c
      - |
        envsubst '$$PTERODACTYL_TOKEN_ID,$$PTERODACTYL_TOKEN' \
          < /config.yml.template \
          > /wings-config/config.yml
  ...
```

Furthermore, for the Pterodactyl Wing service, the init service should be specified as a dependency that needs to be completed before running, like in this example:
```yaml
services:
  wing:
    ... # Omitting for brevity
    depends_on:
      init-config: # So that config.yml is tracked but still can be modified during runtime
        condition: service_completed_successfully
    ...
  ...
```

When using this approach, you will need to provide these environment variables (as secrets via SOPS): `PTERODACTYL_TOKEN_ID` and `PTERODACTYL_TOKEN`. `PTERODACTYL_TOKEN` represents the secret token that the Pterodactyl Wing service will use to connect to the Pterodactyl Panel, and `PTERODACTYL_TOKEN_ID` is the token ID for that token. The values for these variables are usually provided in the auto-generated configuration file created by the Pterodactyl panel for a node (under `Configuration`).