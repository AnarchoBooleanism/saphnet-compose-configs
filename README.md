# saphnet-compose-configs
A set of configuration files for different Docker Compose stacks for Komodo to pull from and run

## Where to deploy each stack

### control-server (control-server.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone`

### docker-host-core (docker-host-core.int-net.saphnet.xyz)
NOTE: `nginx-proxy-manager` is the stack that creates the `web_bridge` network, which is what all of the other web-related stacks depend on.
- `docker-volume-rclone`
- `filestash`
- `guacamole`
- `homepage`
- `netbootxyz`
- `nginx-proxy-manager`
- `openspeedtest`
- `pterodactyl/panel`
- `vert-sh`

### docker-host-pve3 (docker-host-pve3.int-net.saphnet.xyz)
NOTE: This host has an Intel Arc A310 for GPU acceleration.
- `docker-proxy`
- `docker-volume-rclone`
- `deluge-seedbox`
- `foldingathome` (Can be deployed anywhere, but GPU on host preferred, and ideally CUDA)
- `media-server` (Should be deployed on hosts that have a good GPU for transcoding)

### docker-host-pve4 (docker-host-pve4.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone`
- `pterodactyl/wing`

### vps1 (vps1.saphnet.xyz)
- `glances`
- `nginx-vps1`
- `velocity-vps1`
