## docker-proxy
Used as a way to access the internal Docker socket from outside (read-only), mostly by Homepage

**NOTE**: If using this on a host that has a publicly accessible IP address, please use a variety of compose file that has this in mind, and make sure you have a pre-deploy command configured to work in conjunction with it!