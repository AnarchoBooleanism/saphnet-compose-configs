## velocity-vps1
A modern reverse proxy for Minecraft servers, intended for public-facing vps1

When deploying, make sure to set these environment variables with your secrets:
- `VELOCITY_FORWARDING_SECRET` - The forwarding secret to use with Velocity, for the purposes of authentication
- `RCON_PASSWORD` - The password to login into Velocity's RCON server with
- `SFTP_PASSWORD` - The password to login into the SFTP server as `velocity-user` with
- `TAILSCALE_IP` - For the SFTP and RCON servers, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)

When updating Velocity versions, make sure to configure the variable `VELOCITY_VERSION`, which is the Velocity version being targeted, as well as the Java version within the variable `IMAGE_NAME`, which should be a Java version supported by the desired Velocity version.

In the context of the Velocity container, the directory, `/server`, which is mounted to by the volume, `velocity-data`, contains all of the files used by the Velocity server; you are able to access and edit this via the SFTP server (e.g. to add plugins). As well, the directory, `/config`, within which files from our local `velocity-config` directory are mounted, contains various configuration files that get synchronized to the `/server` directory; these configuration files can have environment variable placeholders within them, in the format of `${ENVIRONMENT_VARIABLE}`, that get replaced with their values at runtime. In the local `velocity-config` directory, we have the files `forwarding.secret`, which will be replaced with the `VELOCITY_FORWARDING_SECRET` variable, and `velocity.toml`, which is the main configuration file for Velocity.