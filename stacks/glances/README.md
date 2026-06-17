## Glances
A real-time monitoring tool for systems (e.g. processes and hardware usage), equivalent to top/htop

**NOTE**: `network_mode` is set to `host`, to allow the container access to the host's network stack for monitoring purposes. However, this has the consequence of having Glances being accessible from port 61208. If you want to restrict public access to the information provided by Glances (e.g. process details), make sure to have a firewall rule blocking this port from certain interfaces; as the container uses the host's network stack, Docker will not interfere with the firewall rule.

If you are not concerned about using Traefik, you can use `compose.yaml` as-is. However, if you do, then make sure to use the configuration file for your specific host (e.g. `docker-host-core.yaml`); as well, there is no need to run `compose.yaml`, as the host-specific config will automatically include it.