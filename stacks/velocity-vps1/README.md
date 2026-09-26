## velocity-vps1
A modern reverse proxy for Minecraft servers, intended for public-facing vps1.

When deploying, make sure to set these environment variables with your secrets:
- `VELOCITY_FORWARDING_SECRET` - The forwarding secret to use with Velocity, for the purposes of authentication
- `RCON_PASSWORD` - The password to login into Velocity's RCON server with (**IMPORTANT**: avoid using `#` in your password!)
- `SFTP_PASSWORD` - The password to login into the SFTP server as `velocity-user` with
- `TAILSCALE_IP` - For the SFTP and RCON servers, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)

When updating Velocity versions, make sure to configure the variable `VELOCITY_VERSION`, which is the Velocity version being targeted, as well as the Java version within the variable `IMAGE_NAME`, which should be a Java version supported by the desired Velocity version.

In the context of the Velocity container, the directory, `/server`, which is mounted to by the volume, `velocity-data`, contains all of the files used by the Velocity server; you are able to access and edit this via the SFTP server (e.g. to add plugins). As well, the directory, `/config`, within which files from our local `velocity-config` directory are mounted, contains various configuration files that get synchronized to the `/server` directory; these configuration files can have environment variable placeholders within them, in the format of `${ENVIRONMENT_VARIABLE}`, that get replaced with their values at runtime. In the local `velocity-config` directory, we have the files `forwarding.secret`, which will be replaced with the `VELOCITY_FORWARDING_SECRET` variable, and `velocity.toml`, which is the main configuration file for Velocity.

If you want to run commands within Velocity, make sure to do it with RCON. You can either run it within the container itself, using the `rcon-cli` command, or connect to it remotely (through Tailscale), via port 25575, also using `rcon-cli` or any other program.

### VelocityWhitelist
If you want your Velocity server to start with the [VelocityWhitelist plugin](https://github.com/TISUnion/VelocityWhitelist) right away, there already exists an init container image that you can run to set it up before Velocity starts; its Dockerfile and script file lie in the `init-velocitywhitelist` subdirectory.

To run this image as an init service, you can add this to your Compose stack configuration:
```yaml
services:
  ... # Omitting for brevity
  init-velocitywhitelist:
    build: ./init-velocitywhitelist
    volumes:
      - ./init-velocitywhitelist/setup.sh:/setup.sh:ro
      - velocity-data:/velocity-data
    environment:
      VELOCITYWHITELIST_VERSION: *velocitywhitelist-version
    entrypoint:
      - /setup.sh
```

In this case, it uses the Dockerfile from the subdirectory, and is set up to run the `setup.sh` script right away. As well, `velocity-data` is the volume that stores the data that will be in the `/server` path of the Velocity service container. Importantly, however, you will want to set the `VELOCITYWHITELIST_VERSION` environment variable to a valid SemVer value (with a leading `v` symbol), in order for the script to run; this value can be auto-updated with Renovate.

After adding the init service, you will want to add this to your Velocity service configuration:
```yaml
services:
  velocity:
    ... # Omitting for brevity
    depends_on:
      init-velocitywhitelist:
        condition: service_completed_successfully
    ...
```

This will force the Velocity service to wait until the init service has successfully finished before running. If there is an error, then Velocity will be prevented from starting, which will make sure there are no moments where Velocity is running without the VelocityWhitelist plugin installed.