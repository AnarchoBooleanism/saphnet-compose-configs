# Pterodactyl
A server management panel for games, e.g. Minecraft

TODO: Complete this

php artisan p:user:make
Create new location, homelab
New node in homelab, pterodactyl-node-main.int.saphnet.xyz as FQDN (basically url of behind reverse proxy), HTTP, 64000 MiB disk space, 4096 MiB RAM, 0% over-allocation, 443 as daemon port, 2022 as SFTP port, SSL, behind proxy
0.0.0.0 25565 allocation

Make sure to add this to your config.yml (ensure the subnet is different to what you have in ptero0):
```
docker:
  network:
    interfaces:
      v4:
        subnet: "10.55.230.0/24"
        gateway: 10.55.230.1
```