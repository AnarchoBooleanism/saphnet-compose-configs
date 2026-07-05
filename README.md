# saphnet-compose-configs
A set of configuration files for different Docker Compose stacks for Komodo to pull from and run

Note that this is intended to work in tandem with [saphnet-komodo](https://github.com/AnarchoBooleanism/saphnet-komodo), where `saphnet-komodo` is aware of `saphnet-compose-config`, but not necessarily the other way around!

Furthermore, be aware of the requirements of each Compose stack! Depending on the requirements, you may or may not be able to deploy a specific stack on a particular server, for example, when a stack has a GPU requirement.

## Repository structure

This repository has four main parts to it:
- `.github`: A directory containing the Dependabot config and various GitHub Actions workflows (e.g. for validation)
  - The contents of this directory are mostly supplemental to the other parts of the repository, and won't need to be touched on a regular basis.
- `stacks`: A directory containing all configurations for Compose stacks
  - Each stack has its own subdirectory, either under `stacks`, or directly under a subdirectory under `stacks` (for stacks that are categorized together)
    - For example, the `pterodactyl` subdirectory has two subdirectories: `panel`, for the Pterodactyl Panel stack, and 
- `.sops.yaml`: A configuration file for sops, containing the public keys of all hosts and rules for locating secrets files
- `SERVER-NAME.toml` (where `SERVER-NAME` stands in for the various Komodo servers hosting the stacks): A Komodo resource file describing Server-specific resource syncs, the Stacks that a specific Server will run ("S" is capitalized in this case to represent that this is the Komodo resource, named as a "Stack", as opposed to the Compose configuration behind it, the stack), and the configuration for how Komodo will deploy the stack

## Updating Compose stacks

Assuming that your stack's compose files use version pinning, the updating process should be relatively simple, with no setup required. On a weekly basis (every Monday), Dependabot will scan through all Compose files for outdated (or vulnerable) image versions, automatically creating pull requests with updates for all images that can be updated; it is also possible to configure Dependabot to group updates for certain image names together into one single pull request.

It is generally a good idea to check for any breaking changes with new versions that require configuration changes or manual work, before merging such changes; if new versions require configuration changes (applicable to the files within the repository), make sure to push those changes to the branch for the pull request **before** merging it into the main branch!

Once you are finished with merging all possible changes, you will still need to run specific procedures in Komodo so that the new changes can be deployed, as it is not fully automatic; this is to ensure there is a manual verification step before running new code. Within Komodo, run the `saphnet-repo-sync` Procedure, which will bring Komodo's copy of the repositories up to date, as well as update the `stack-sync` Resource Syncs. Then, after manually reviewing the changes in each `stack-sync` Resource Sync for each Server, confirming that there are no discrepancies or errors, run the `saphnet-run-iac-stack-sync` Procedure; this will bring all Stacks to the states specified in the repository's Resource Syncs and redeploy any Stacks that have changes.

### On Dependabot (configuration)
Dependabot is equipped to work with any new stacks in subdirectory of the `stacks` directory (or a subdirectory of that subdirectory), as long as the YAML files (which can be given any name) for the Compose stacks are valid YAML, following the Compose schema. The default behavior is to create individual pull requests for each Docker image, which may be fine for certain types of needs. However, if you have multiple Docker images that are always upgraded together, you may want to update all of them at once in a single pull request; in that case, you are able to define groups in the Dependabot configuration (in `.github/dependabot.yml`) consisting of multiple Docker image names that will be considered together in pull requests.

Here is an example of such a group in Dependabot:
```yaml
updates:
  ... # Omitting for brevity
  - package-ecosystem: "docker-compose"
    ...
    groups:
      guacamole:
        patterns:
          - "guacamole/guacd"
          - "guacamole/guacamole"
      ...
```

Under the top-level attribute `updates`, in the entry for the `docker-compose` package ecosystem, in `groups`, a group named `guacamole` is defined, with the patterns `guacamole/guacd` and `guacamole/guacamole`; the patterns in this case just literally refer to the names of the Docker images referenced, but you are able to use the wildcard pattern (`*`) as well to refer to all images. Whenever both the `guacamole/guacd` and `guacamole/guacamole` images have updates when Dependabot runs, Dependabot will automatically combine their updates into a single pull request.

Note that, for the strings under `patterns`, that you only need to specify the repository name (and potentially the namespace name) for the image, in this format: `[NAMESPACE/]REPOSITORY` (note that `NAMESPACE` is shown as optional here). You should not add the registry host name (and port), even if the image does not come from the default image registry (e.g. `ghcr.io`). For example, an image that would be referred to with `ghcr.io/tecnativa/docker-socket-proxy` in a Compose file only needs to be written as `technativa/docker-socket-proxy` in the Dependabot configuration.

Furthermore, it is only advised to group together images that are related or closely work together; if the image is also used in other unrelated stacks, the resulting pull requests from Dependabot may create undue coupling between stacks.

For more information, [you can read the official Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#groups--).

### Running Dependabot manually
Generally, Dependabot runs on a weekly schedule, being on Mondays, at a random time. In the case that you need Dependabot to run again, outside of this schedule (e.g. to scan for images that were just recently updated), you are able to manually run Dependabot through the GitHub website. On the GitHub webpage for this repository, navigate to `Insights` on the top bar (for the repository), click on `Dependency graph` on the side menu bar, navigate to the `Dependabot` menu (under `Dependancy graph`), click on `Recent update jobs` for the entry that names a `compose.yaml` file, and, finally, click `Check for Updates`. You can confirm that Dependabot is running by navigating to `Actions` on the top bar and checking for workflows that are labeled with `Dependabot Updates`.

## Creating Compose stacks

*For a more comprehensive reference for creating Compose stacks*, [please check out the official Compose specification](https://github.com/compose-spec/compose-spec)!

A Compose stack, generally individually specified for specific services or sets of related services, defines applications as services through Docker containers; in addition to services, stacks also define other objects, such as networks and volumes, that support the service(s). Compose stacks allow you to deploy multiple interconnected applications, all at once, with all configuration, such as environment variables and links, all defined in a single YAML file (the Compose file); this allows for increased portability and reproducibility, as compared to manually configuring the applications, one-by-one. For the purposes of the Sapphic Homelab/Home Server, stacks are used for the deployment of services (applications that do work, but don't required dedicated VMs) in Komodo. The stacks defined in this repository are able to be used outside of Komodo, provided that the surrounding configuration is set up, but we will generally write stacks in a way that best utilizes the features of Komodo, to be used in Komodo's Stack resources.

To create a new Compose stack for a certain service (or set of services), you are welcome to copy a pre-existing Compose file off of the internet and adapted it to the standards laid out in this guide. You are also able to create a Compose file from scratch. The bare minimum needed for a valid Compose stack is to have an entry (with a name) for a service, under the `services` top-attribute, that contains a reference to a valid image name (or a reference to a Dockerfile), like this:
```yaml
services:
  example:
    image: busybox
```

Running the command, `docker compose up`, on the above configuration will spin up a Docker container for the `example` service, with the `busybox` image. However, this is not very useful, by itself, since the `busybox` image, by default, is only configured to run a shell (and nothing else), and without an interactive terminal, it will exit as soon as it is started. A useful stack (to be run standalone) consists of service(s) with primary applications (which do work) that will continuously run without an interactive shell or manual input. Furthermore, it often has exposed ports for the outside world to connect to, connections to other services or Docker containers (via networks), access to persistent storage (via volumes), and manually specified commands that are run when the container is started (via the entrypoint).

For example, here is a slightly less bare-bones example of a service, `filestash` (note that this example is simplified, compared to the configuration in the actual `filestash` stack):
```yaml
services:
  filestash:
    image: machines/filestash:latest@sha256:218844c9b8121fa29529373311502ff203bc86b8210bd90e473b5849e089505f
    container_name: filestash
    ports:
    - "8334:8334"
    environment:
      APPLICATION_URL: filestash.int.saphnet.xyz
      CANARY: "true"
      OFFICE_URL: http://127.0.0.1:9980
      OFFICE_FILESTASH_URL: http://app:8334
    volumes:
      - filestash:/app/data/state/
    restart: unless-stopped

volumes:
  filestash:
```

In this example, the `filestash` service is given the image `machine/filestash`, which is configured to run the Filestash, the main application of the stack. The container, created from the image, is then given various environment variables, such as `APPLICATION_URL`, which tell the application to behave in a specific way; environment variables are highly useful for the configuration of any Docker container. The stack defines a volume, `filestash`, which is used to store persistent data; the contents of volume are mounted to `/app/data/state` in the container, for the container to read and write to (the data of a container are deleted after the container is taken down). As well, under `ports`, port 8334 on the container is mapped to port 8334 on the host, so that machines outside the host can communicate with the container through the port on the host; note that the port on the left side is the host's port, and the port on the right side is the container's port.

Furthermore, note that `container_name` is `filestash`; this means that when containers outside of the stack want to communicate with the container, they will use the hostname, `filestash`, as, by default, when `container_name` is not specified, the hostname of the container is `STACKNAME_SERVICENAME` (service name, in this case is the name of the attribute used to define the `filestash` service, under `services`). As well, `restart`, for the `filestash` service, is specified as `unless-stopped`; this means that if, for whatever reason, the container exits (e.g. when crashing), then the container will automatically be restarted, unless it is manually stopped. In general, for stack services in this repository, the convention is to have `container_name` be the name as the name of the service, and to have `restart` be `unless-stopped`.

If starting completely from scratch (e.g. when deploying applications that weren't designed for containerization), then the best course of action is to think through the process of manually configurating and starting the application, and determine which Compose features are best suited to perform each step for you:
- **Does the application require that you provide arguments when starting it, for specific functionality? (e.g. to start in a certain mode)** If so, create a list of strings, under the `arguments` attribute of a service, that represent the arguments being provided to the application.
- **Do you typically specify environment variables for the application to work in a specific way? (e.g. to connect to a specific external server)** If so, list those environment variables under the `environment` attribute of a service, preferably in dictionary format (in the format of `ENVIRONMENT_VARIABLE_NAME: value`). You can also pass the paths of .env files as a list under the `env_file` attribute of a service.
- **Does the application expect to have other configuration files given to it when running?** If so, make sure to have those configuration files available within the subdirectory of the stack, and mount them to their specific locations on the container, as entries under the `volumes` attribute of the service; this would look like `./config.toml:/var/lib/config.toml:ro`, where the `config.toml` file, in the same directory as the Compose file, is mounted to where an application would look.
- **Is the application supposed to be connected to, via specific ports?** If so, make sure to add mappings of host ports to container ports as string entries in a list under the `ports` attribute of the service; the format for each mapping is `PORT_ON_HOST:PORT_ON_CONTAINER`.
- **Does the application write/read persistent data to/from a specific location, particularly between runs?** If so, make sure to create a volume as a dictionary entry under the top-level `volumes` attribute, and then mount it as a directory to the service, as a string entry under the `volumes` attribute (a list) of the service, in the format of `VOLUME_NAME:/PATH/ON/CONTAINER`.
- **Does the application expect to communicate with other applications that are started with it?** If so, create a network as a dictionary entry under the top-level `networks` attribute, and then, for each service that requires connectivity to other services, add the name of the network to the list that is the `networks` attribute of the service, as a string. As a note, make sure that each application is aware of the hostnames of the other services.
- **Does the application require multiple commands, extra setup, etc. before running?** If so, modify the `entrypoint` attribute of the service to start a shell (e.g. `/bin/bash`), and then, under the `cmd` attribute of the service, specify the list of commands (the script) that are needed to perform the extra setup, and finally, specify the command that will run the main application. If the script is lengthy, you can have it as a separate script file that then gets mounted to the service (under the `volumes` attribute of the service), and then have the `entrypoint` attribute of the service refer to the location of the script (within the container). If the setup doesn't need to be done within the service itself (e.g. when what is being set up is external to the service), you can create a special sidecar service with a special script/entrypoint that runs before the main service.

No matter how you start writing your Compose file, you should try to follow the guidelines laid out in the following subsections.

### Reproducibility (highly important for IaC and Dependabot!)
- stuff about pinning, and also still specifying a version (for dependabot), how to do it by looking through things

```yaml
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz:latest@sha256:39bb40c85d1f6e500b3df1871460f88609215735c224b234b9e6e4e849faf92b
    ... # Omitting for brevity
```

```yaml
services:
  ... # Omitting for brevity
  cache:
    image: redis:8@sha256:2838d5524559494f6f1cd66e97e76b200d64a633a8614200620755ed395daf32
    ...
```

```yaml
services:
  ... # Omitting for brevity
  panel:
    image: ghcr.io/pyrodactyl-oss/pyrodactyl:v5.0.6@sha256:3c1008e2b9337655e60100eaff0fc4dcda4cad4834ae3cced9ab3baf861ad955
    ...
```

### Structure
- stuff about compose.yaml, and if supporting multiple hosts, about naming files after servers, and then splitting things into base file and then server specific yaml files to run together
    - also add note on being able to have two separate files that get combined by komodo, or main file as dependency by other file
- special section on secrets file, making sure they're named after servers running stack (since separate values per server), and to have .enc.env
- section on other files, like scripts, other config files, more compose things to pull in, etc, being flexible on them, but if there are different categories of files for different things, then best to group them together, since you can map things in any way in compose file
- of course have the readme!
- and then note about how these files will be reference in server-specific resource in stack config (so make sure file names/paths line up)
### Formatting
- make sure to keep things up to latest style and version of compose, so no version of compose listed! https://github.com/compose-spec/compose-spec
- make sure to specify the order in which to list attributes
    - order in top level attributes
    - order per service
- write stuff about spacing between sections, also indentation
- and then for sections where you can select between lists and key-values, prefer key-values for consistency and ease of fragment use
- also make sure variables are screaming snake case
- and then have comment on top describing environment variables to set and other certain things to be careful about
- note about how to reference environment variables (from host, not container)
- write note about making sure strings that may be interpreted as numbers, etc, are wrapped in quotes to stay strings
- maybe other things like line length
- also write about grouping things together, for stuff like environment variables, but still having consistent order between in file and in comments/docs
### Arguments (for the program being run as the entrypoint)
- 
### Environment variables, fragments, and overall plumbing
- 

```yaml
services:
  postgres:
    ... # Omitting for brevity
    environment:
      ...
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_NON_ROOT_PASSWORD: "${POSTGRES_NON_ROOT_PASSWORD}"
    ...
```

```yaml
services:
  vert:
    ... # Omitting for brevity
    environment:
      ...
      PORT: "${PORT:-3000}"
      ...
```

```yaml
services:
  netbootxyz:
    ... # Omitting for brevity
    labels:
      ...
      traefik.http.middlewares.netboot-auth.basicauth.users: "${NETBOOT_LOGIN}"
    environment:
      ...
    ...
```

```yaml
services:
  ... # Omitting for brevity

  # This expects to be given a path to a secrets file (by the "docker compose up" command)
  # to use for secrets as environment variables
  homepage:
    ...
    env_file:
      - ./.env
      - ${SOPS_SECRETS_PATH:?Please set SOPS_SECRETS_PATH}
```

```yaml
# Common variables, declared here
x-common:
  TIMEZONE: &timezone "America/Los_Angeles"
  ... # Omitting for brevity

...

services:
  ...
  seerr:
    ...
    environment:
      LOG_LEVEL: debug
      TZ: *timezone
    ...
```

```yaml
# Common variables, declared here
x-common:
  ... # Omitting for brevity
  database: &db-environment
    MYSQL_PASSWORD: &db-password "basic_mysql_password"
    MYSQL_ROOT_PASSWORD: "basic_mysql_root_password"
  ...

services:
  database:
    ...
    environment:
      <<: *db-environment
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
    ...
```

```yaml
x-common:
  ... # Omitting for brevity
  MAIL: &mail
    ...
    N8N_SMTP_PASS: "${MAIL_PASSWORD}"
    ...
```

#### Secrets
- note about them being in special secrets subdirectory, being .enc.env (env format)
- also note that the compose file doesn't interact with them, komodo reads the secrets and then makes them environment variables for docker compose to read and then pass to container as compose file sees fit
- notes about how they're parsed! how they're imported, on quotation marks (sops doesn't strip them, bash does), and when to backslash or not (with `$`)

```ini
EXAMPLE_VARIABLE=foobar
EXAMPLE_VARIABLE_2=abcd$1234$=
```

```sh
EXAMPLE_VARIABLE='foobar'
EXAMPLE_VARIABLE_2='abcd$1234$='
```

### Networking
- add note about external networks, and being sure to name things so that they're externally accessible
- add note about web_bridge, making sure external
- add note about Docker and firewalls!
- add note about having custom networks, and if needing containers to connect to each other if custom networks still, make sure to have stack-specific network that everything is connected to
- ports and HOST_IP variables

```yaml
services:
  foldingathome:
    image: ... # Omitting for brevity
    container_name: foldingathome
    ...
```

```yaml
services:
  ... # Omitting for brevity
  deluge-sftp:
    ...
    ports:
      - "2222:22"
    ...
```

```yaml
services:
  foldingathome:
    image: ... # Omitting for brevity
    container_name: foldingathome
    ...
    networks:
      - web_bridge

networks:
  web_bridge:
    name: web_bridge
    external: true
```

```yaml
services:
  database:
    ... # Omitting for brevity
    networks:
      - pterodactyl_panel_internal
    ...
  
  cache:
    ...
    networks:
      - pterodactyl_panel_internal
    ...
  
  panel:
    ...
    container_name: pterodactyl-panel # Refer to the panel container this way
    ...
    networks:
      - web_bridge
      - pterodactyl_panel_internal
    ...

...

networks:
  pterodactyl_panel_internal:
  web_bridge:
    name: web_bridge
    external: true
```

```yaml
services:
  glances:
    ... # Omitting for brevity
    network_mode: host # Make sure to set firewall rules accordingly!
    # Note that since network_mode is "host", Glances uses the network space of the host,
    # meaning that it will attach to port 61208 on the host automatically.
    # ports:
    #   - "61208:61208"
    ...
```

```yaml
services: # To be connected to by Homepage
  docker-proxy:
    ... # Omitting for brevity
    ports:
      - "${HOST_IP:-0.0.0.0}:2375:2375"
    ...
```

### Volumes, mounting
- 

```yaml
volumes:
  velocity-data:
```

```yaml
services:
  velocity:
    ... # Omitting for brevity
    volumes:
      ...
      - velocity-data:/server
```
#### Mounting non-Compose config files (including Compose files not directly opened by Komodo!)
- stuff about making sure relative to root of stack directory
- note about read-only, to avoid potential issues, since it is IaC

```yaml
services:
  velocity:
    ... # Omitting for brevity
    volumes:
      - ./velocity-config/velocity.toml:/config/velocity.toml:ro
```

```yaml
services:
  cpu: {}

  nvenc:
    deploy:
      ... # Omitting for brevity
  
  ...
```

```yaml
services:
  immich-server:
    ... # Omitting for brevity
    extends:
      file: ./extra/hwaccel.transcoding.yaml
      service: quicksync
```

#### NAS storage mounts
- 

```yaml
volumes:
  ... # Omitting for brevity
  netboot-assets: # Bootable assets (e.g. live CDs)
    driver_opts:
      type: "nfs"
      o: "addr=nas1.int-net.saphnet.xyz,nolock,soft,rw,nfsvers=4"
      device: ":/mnt/saphnet-nas1c/netboot-assets"
```

```yaml
services:
  netbootxyz:
    ... # Omitting for brevity
    volumes:
      ...
      - netboot-assets:/assets
      ...
```

### Traefik
- redirect them to traefik README
- still, give them a basic explainer on what they need for bare minimum traefik setup

*More on how to configure Traefik*: [Traefik README](stacks/traefik/README.md)

```yaml
services:
  jellyfin:
    image: ... # Truncating here
    labels:
      traefik.enable: true
      traefik.http.routers.jellyfin.rule: Host(`jellyfin.media.int.saphnet.xyz`)
      traefik.http.routers.jellyfin.entrypoints: websecure
      traefik.http.routers.jellyfin.tls: true
      traefik.http.routers.jellyfin.tls.certresolver: letsencrypt
      ## HTTP Service
      traefik.http.routers.jellyfin.service: jellyfin-svc
      traefik.http.services.jellyfin-svc.loadBalancer.server.port: "8096"
    networks:
      - web_bridge # Traefik, in this instance, connects to services via the web_bridge network, so we need to be reachable through it
    ... # Again, truncating
    restart: unless-stopped
```

### Other custom functionality (scripts, entrypoints, sidecar services)
- 

### Writing a README
- tldr: basically write for someone who knows nothing about the stack, but wants to instantiate something for a specific server, though assume they know docker and such, give them enough to get something from scratch
- give a quick description, this will be used in the Stack description too
- give notes and warnings about things to watch out, dependencies, etc
- describe environment variables to pass
- if stack requires manual work after deploying, guide them through all the steps, the more they can copy and paste, the better

## Setting up Stacks in Komodo resource file
TODO: Plumbing stacks
- 

```toml
# glances
[[stack]]
name = "glances-vps1"
description = "A real-time monitoring tool for systems (e.g. processes and hardware usage), equivalent to top/htop."
tags = ["glances", "iac"]
[stack.config]
server = "vps1"
poll_for_updates = true
auto_update = true
auto_update_all_services = true
destroy_before_deploy = true
linked_repo = "saphnet-compose-configs"
run_directory = "stacks/glances"
file_paths = ["vps1.yaml"]
config_files = [
  { path = "compose.yaml", requires = "Redeploy" }
]
```

### On tags
- note that all stacks defined here must have iac tag! to distinguish from manually created stacks
- if stack is one of many in certain category (either from same stack files or do connected things), must have tag for that shared between them, before the iac tag
- if stack requires something or works best in certain config (like gpu or high-availability), have tags for that after iac tag

```toml
# docker-proxy
[[stack]]
name = "docker-proxy-pve3"
... # Omitting for brevity
tags = ["docker-proxy", "iac"]
[stack.config]
...
```

```toml
# foldingathome
[[stack]]
name = "foldingathome"
... # Omitting for brevity
tags = ["iac", "gpu"]
[stack.config]
...
```

### On non-Compose config files
- if compose file references other files in repo, or if there is secrets file that komodo reads, must add it to extra config files, so that komodo can track it and take right action (e.g. redeploy) if changes made to these files
- if the file is read only at deploy time, do redeploy
- if the file is read only at container start time, do restart
- if it doesn't matter, but is file that is continuously dynamically read, do none

```toml
# n8n
[[stack]]
name = "n8n"
... # Omitting for brevity
[stack.config]
...
config_files = [
  { path = "secrets/docker-host-core.enc.env", requires = "Redeploy" },
  { path = "init-data.sh", requires = "Restart" }
]
```

### On environment variables (important caveats)
TODO: Environment variables, how they're imported, on quotation marks, and when to backslash or not (with `$`)
- 

```toml
[[stack]]
name = "example-stack"
... # Omitting for brevity
[stack.config]
...
environment = """
EXAMPLE_VAR_1 = "foobar"
EXAMPLE_VAR_2 = "[[KOMODO_EXAMPLE_VAR_1]]"
EXAMPLE_VAR_3 = "abc\$d1234\$_5"
"""
```

#### Passing in secrets (with sops)
- always should be in secrets, as .enc.env file (we want this to be an environment variable file, like how komodo handles environment)
- again, if secret file exists, make sure listed in config_files
- make sure to do compose_cmd_wrapper AND compose_cmd_wrapper_include
- two ways to pass sops env
    - sops exec-env secrets/docker-host-core.enc.env '[[COMPOSE_COMMAND]]' for when all environment variables being looked for are defined in file (normal way)
        - this just puts everything in environment
        - if doing this way, no quotes, or escaping $, because sops interpreting files very literally
    - "sops exec-file --no-fifo secrets/docker-host-core.enc.env 'export SOPS_SECRETS_PATH={} && [[COMPOSE_COMMAND]]'" for when compose file doesn't list all environment variables but expects us to pass in anyways (useful for when there are many environment variables, are such)
        - this puts everything into a file, passing in the path as environment variables, which compose file will pull as env file
        - values won't be accessible to within compose file, though
        - if doing this way, bash is parsing it, so should use quotes, and MUST escape $ with backslash (at least with double quotes? single quotes not a problem)

```toml
# netbootxyz
[[stack]]
name = "netbootxyz"
# Omitting for brevity
[stack.config]
...
config_files = [
  { path = "secrets/docker-host-core.enc.env", requires = "Redeploy" },
  ...
]
compose_cmd_wrapper = "sops exec-env secrets/docker-host-core.enc.env '[[COMPOSE_COMMAND]]'"
compose_cmd_wrapper_include = ["up", "config", "build", "pull", "run"]
...
```

```yaml
services:
  netbootxyz:
    ... # Omitting for brevity
    labels:
      ...
      # Basic‑auth middleware
      traefik.http.routers.netboot.middlewares: netboot-auth
      traefik.http.middlewares.netboot-auth.basicauth.users: "${NETBOOT_LOGIN}"
    ...
```

```ini
EXAMPLE_VARIABLE=foobar
EXAMPLE_VARIABLE_2=abcd$1234$=
```

```toml
# homepage
[[stack]]
name = "homepage"
... # Omitting for brevity
[stack.config]
...
config_files = [
  { path = "secrets/docker-host-core.enc.env", requires = "Redeploy" }
]
...
# We do it this way since the Compose config leaves out environment variables,
# instead expecting us to give a path to a .env file with variables to give the service
compose_cmd_wrapper = "sops exec-file --no-fifo secrets/docker-host-core.enc.env 'export SOPS_SECRETS_PATH={} && [[COMPOSE_COMMAND]]'"
compose_cmd_wrapper_include = ["up", "config", "build", "pull", "run"]
...
```

```yaml
services:
  ... # Omitting for brevity
  # This expects to be given a path to a secrets file (by the "docker compose up" command)
  # to use for secrets as environment variables
  homepage:
    ...
    env_file:
      - ./.env
      - ${SOPS_SECRETS_PATH:?Please set SOPS_SECRETS_PATH}
...
```

```sh
EXAMPLE_VARIABLE='foobar'
EXAMPLE_VARIABLE_2='abcd$1234$='
```

#### Using Komodo variables
TODO: Write about variables, particularly Komodo variables
- 

```toml
# immich
[[stack]]
name = "immich"
... # Omitting for brevity
[stack.config]
...
environment = """
TAILSCALE_IP = "[[TAILSCALE_IP_PVE3]]"
"""
```

## Setting up new hosts/servers
TODO: Write about new servers, tags, .sops.yaml, komodo stuff, also note on making sure saphnet-komodo is ready, and to add specific lines to procedures
- 

```toml
[[procedure]]
name = "example-server_redeploy-changed"
description = "A procedure that redeploys all IaC stacks that have had changes to their config or config files, for example-server."
tags = ["redeploy-changed", "iac"]

[[procedure.config.stage]]
name = "Stage 1"
enabled = true
executions = [ # Make sure to give all the names of all stacks here!
  { execution.type = "BatchDeployStackIfChanged", execution.params.pattern = """
example-stack-1
example-stack-2
""", enabled = true }
]
```

```yaml
keys:
  - &admin age1ute399nzja7le5um48rzdg2nj4c7rf5jvhj7slh05mt5x79nr4wqqlwkdj
  ... # Omitting for brevity
  - &example-server ageEXAMPLEKEYHERE
creation_rules:
  ...
  - path_regex: (^|\/)secrets\/example-server\.enc\.env$
    key_groups:
    - age:
      - *admin
      - *example-server
```