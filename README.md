# saphnet-compose-configs
A set of configuration files for different Docker Compose stacks for Komodo to pull from and run

## Where to deploy each stack
Note that for most hosts, there are stacks that require the `web_bridge` network, which should be created by an instance of `traefik`.

### control-server (control-server.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone`

### docker-host-core (docker-host-core.int-net.saphnet.xyz)
- `docker-volume-rclone`
- `traefik` (`base.yaml` and `docker-host-core.yaml`)
- `filestash`
- `guacamole`
- `homepage`
- `netbootxyz`
- `openspeedtest`
- `pterodactyl/panel`
- `vert-sh`
- `n8n`

### docker-host-pve3 (docker-host-pve3.int-net.saphnet.xyz)
NOTE: This host has an Intel Arc A310 for GPU acceleration.
- `docker-proxy`
- `docker-volume-rclone`
- `traefik` (`base.yaml` and `docker-host-pve3.yaml`)
- `deluge-seedbox`
- `foldingathome` (Can be deployed anywhere, but GPU on host preferred, and ideally CUDA)
- `media-server` (Should be deployed on hosts that have a good GPU for transcoding)
- `immich` (Should be deployed on hosts that have a good GPU for transcoding & machine learning)

### docker-host-pve4 (docker-host-pve4.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone`
- `traefik` (`base.yaml` and `docker-host-pve4.yaml`)
- `pterodactyl/wing`

### vps1 (vps1.saphnet.xyz)
- `traefik` (`base.yaml` and `vps1.yaml`)
- `glances`
- `velocity-vps1`

## Note for Komodo environment variables
If the values of environment variables include the character `$`, make sure it's escaped with a backslash (`\`) beforehand!