# saphnet-compose-configs
A set of configuration files for different Docker Compose stacks for Komodo to pull from and run

## Where to deploy each stack

### control-server (control-server.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone`

### docker-host-nginx (docker-host-nginx.int-net.saphnet.xyz)
- `docker-volume-rclone`
- ALL stacks in `nginx-stacks`. Make sure the host has access to the Tailscale network as well.
- `pterodactyl/panel`

### docker-host-pve1 (docker-host-pve1.int-net.saphnet.xyz)
- `docker-proxy`
- `docker-volume-rclone` (if applicable)
- `netbootxyz`

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
- `nginx-stacks/nginx-proxy-manager`
- `pterodactyl/wing`
