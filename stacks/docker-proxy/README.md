## docker-proxy
Used as a way to access the internal Docker socket from outside (read-only), mostly by Homepage.

**NOTE**: If using this on a host that has a publicly accessible IP address, make sure you specify a non-public IP address to restrict the port to, as HOST_IP!