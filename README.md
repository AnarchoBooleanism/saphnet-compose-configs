# saphnet-compose-configs
Compose stack configurations for Komodo to pull from and run, for the Sapphic Homelab/Home Server

Note that this is intended to work in tandem with [saphnet-komodo](https://github.com/AnarchoBooleanism/saphnet-komodo), where `saphnet-komodo` is aware of `saphnet-compose-config`, but not necessarily the other way around!

Furthermore, be aware of the requirements of each Compose stack! Depending on the requirements, you may or may not be able to deploy a specific stack on a particular server, for example, when a stack has a GPU requirement.

## Repository structure

This repository has four main parts to it:
- `.github`: A directory containing the Dependabot config and various GitHub Actions workflows (e.g. for validation)
  - The contents of this directory are mostly supplemental to the other parts of the repository, and won't need to be touched on a regular basis.
- `stacks`: A directory containing all configurations for Compose stacks
  - Each stack has its own subdirectory, either under `stacks`, or directly under a subdirectory under `stacks` (for stacks that are categorized together)
    - For example, the `pterodactyl` subdirectory has two subdirectories: `panel`, for the Pterodactyl Panel stack, and `wing`, for the Pterodactyl Wings stack(s).
  - Under each stack directory are these components:
    - `secrets` (optional): Contains sops-encrypted secrets file for each Server hosting the stack, each file being named in the vein of `SERVER-NAME.enc.env`
    - `compose.yaml` (or multiple Compose YAML files): Contains the Compose files used to make up the stack
    - Other config files, Compose or non-Compose (optional)
  - As well, each direct subdirectory of `stacks` has a `README.md` file for the stack(s) it contains.
- `.sops.yaml`: A configuration file for sops, containing the public keys of all hosts and rules for locating secrets files
- `SERVER-NAME.toml` (where `SERVER-NAME` stands in for the various Komodo servers hosting the stacks): A Komodo resource file describing Server-specific resource syncs, the Stacks that a specific Server will run ("S" is capitalized in this case to represent that this is the Komodo resource, named as a "Stack", as opposed to the Compose configuration behind it, the stack), and the configuration for how Komodo will deploy the stack

This is what the directory structure should look like:
```
Repository root (./.)
│
├─ .github
│   ├─ workflows
│   │   ├─ compose-lint.yml
│   │   └─ (Potentially, other workflows)
│   └─ dependabot.yml
├─ stacks
│   ├─ (A typical stack)
│   │   ├─ secrets (optional)
│   │   │   ├─ SERVER-NAME.enc.env (SERVER-NAME stands in for a Server resource's name)
│   │   │   └─ (Potentially, secrets files for other Servers)
│   │   ├─ README.md (Covering the stack in this subdirectory)
│   │   ├─ compose.yaml (This file can be split into multiple YAML files, depending on the stack setup)
│   │   └─ (Potentially, other config files/directories, either Compose or non-Compose)
│   ├─ (A directory whose subdirectories are stacks that fall into common categories)
│   │   ├─ README.md (covering all the stacks in this subdirectory)
│   │   ├─ (A stack, in the structure of the above typical stack example) 
│   │   └─ (Other stack(s))
│   └─ (Other stacks/groups of stacks)
├─ .sops.yaml
├─ SERVER-NAME.toml (SERVER-NAME stands in for a Server resource's name)
├─ (Potentially, TOML files for other Servers)
└─ (Other repository-related files, including this README)
```

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

*For a more comprehensive reference for creating Compose stacks, [please check out the official Compose specification](https://github.com/compose-spec/compose-spec)!*

A Compose stack, generally individually specified for specific services or sets of related services, defines applications as services through Docker containers; in addition to services, stacks also define other objects, such as networks and volumes, that support the service(s). Compose stacks allow you to deploy multiple interconnected applications, all at once, with all configuration, such as environment variables and links, all defined in a single YAML file (the Compose file); this allows for increased portability and reproducibility, as compared to manually configuring the applications, one-by-one. For the purposes of the Sapphic Homelab/Home Server, stacks are used for the deployment of services (applications that do work, but don't required dedicated VMs) in Komodo. The stacks defined in this repository are able to be used outside of Komodo, provided that the surrounding configuration is set up, but we will generally write stacks in a way that best utilizes the features of Komodo, to be used in Komodo's Stack resources.

To create a new Compose stack for a certain service (or set of services), you are welcome to copy a pre-existing Compose file off of the internet and adapted it to the standards laid out in this guide. You are also able to create a Compose file from scratch. The bare minimum needed for a valid Compose stack is to have an entry (with a name) for a service, under the `services` top-attribute, that contains a reference to a valid image name (or a reference to a Dockerfile), like this:
```yaml
services:
  example:
    image: busybox
```

Running the command, `docker compose up`, on the above configuration spins up a Docker container for the `example` service, with the `busybox` image. However, this is not very useful by itself, since the `busybox` image, by default, is only configured to run a shell (and nothing else), and without an interactive terminal, it exits as soon as it is started. A useful stack (to be run standalone) consists of service(s) with primary applications (which do work) that will continuously run without an interactive shell or manual input. Furthermore, it often has exposed ports for the outside world to connect to, connections to other services or Docker containers (via networks), access to persistent storage (via volumes), and manually specified commands that are run when the container is started (via the entrypoint).

For example, here is a slightly less bare-bones example of a service, `filestash` (note that this example is simplified, compared to the configuration in the actual `filestash` stack):
```yaml
services:
  filestash:
    image: machines/filestash:latest@sha256:218844c9b8121fa29529373311502ff203bc86b8210bd90e473b5849e089505f
    container_name: filestash
    volumes:
      - filestash:/app/data/state/
    environment:
      APPLICATION_URL: filestash.int.saphnet.xyz
      CANARY: "true"
      OFFICE_URL: http://127.0.0.1:9980
      OFFICE_FILESTASH_URL: http://app:8334
    ports:
    - "8334:8334"
    restart: unless-stopped

volumes:
  filestash:
```

In this example, the `filestash` service is given the image `machine/filestash`, which is configured to run the Filestash, the main application of the stack. The container, created from the image, is then given various environment variables, such as `APPLICATION_URL`, which tell the application to behave in a specific way; environment variables are highly useful for the configuration of any Docker container. The stack defines a volume, `filestash`, which is used to store persistent data; the contents of volume are mounted to `/app/data/state` in the container, for the container to read and write to (the data of a container are deleted after the container is taken down). As well, under `ports`, port 8334 on the container is mapped to port 8334 on the host, so that machines outside the host can communicate with the container through the port on the host; note that the port on the left side is the host's port, and the port on the right side is the container's port.

Furthermore, note that `container_name` is `filestash`; this means that when containers outside of the stack want to communicate with the container, they will use the hostname, `filestash`, as, by default, when `container_name` is not specified, the hostname of the container is `STACKNAME_SERVICENAME` (service name, in this case is the name of the attribute used to define the `filestash` service, under `services`). As well, `restart`, for the `filestash` service, is specified as `unless-stopped`; this means that if, for whatever reason, the container exits (e.g. when crashing), then the container will automatically be restarted, unless it is manually stopped. In general, for stack services in this repository, the convention is to have `container_name` be the name of the service, and to have `restart` be `unless-stopped`.

If starting completely from scratch (e.g. when deploying applications that weren't designed for containerization), then the best course of action is to think through the process of manually configurating and starting the application, and determine which Compose features are best suited to perform each step for you:
- **Does the application require that you provide arguments when starting it, for specific functionality? (e.g. to start in a certain mode)** If so, create a sequence of strings, under the `arguments` attribute of a service, that represent the arguments being provided to the application.
- **Do you typically specify environment variables for the application to work in a specific way? (e.g. to connect to a specific external server)** If so, sequence those environment variables under the `environment` attribute of a service, preferably in dictionary format (in the format of `ENVIRONMENT_VARIABLE_NAME: value`). You can also pass the paths of .env files as a sequence under the `env_file` attribute of a service.
- **Does the application expect to have other configuration files given to it when running?** If so, make sure to have those configuration files available within the subdirectory of the stack, and mount them to their specific locations on the container, as entries under the `volumes` attribute of the service; this would look like `./config.toml:/var/lib/config.toml:ro`, where the `config.toml` file, in the same directory as the Compose file, is mounted to where an application would look.
- **Is the application supposed to be connected to, via specific ports?** If so, make sure to add mappings of host ports to container ports as string entries in a sequence under the `ports` attribute of the service; the format for each mapping is `PORT_ON_HOST:PORT_ON_CONTAINER`.
- **Does the application write/read persistent data to/from a specific location, particularly between runs?** If so, make sure to create a volume as a dictionary entry under the top-level `volumes` attribute, and then mount it as a directory to the service, as a string entry under the `volumes` attribute (a sequence) of the service, in the format of `VOLUME_NAME:/PATH/ON/CONTAINER`.
- **Does the application expect to communicate with other applications that are started with it?** If so, create a network as a dictionary entry under the top-level `networks` attribute, and then, for each service that requires connectivity to other services, add the name of the network to the sequence that is the `networks` attribute of the service, as a string. As a note, make sure that each application is aware of the hostnames of the other services.
- **Does the application require multiple commands, extra setup, etc. before running?** If so, modify the `entrypoint` attribute of the service to start a shell (e.g. `/bin/bash`), and then, under the `cmd` attribute of the service, specify the commands that are needed to perform the extra setup, and finally, specify the command that will run the main application. If the script is lengthy, you can have it as a separate script file that then gets mounted to the service (under the `volumes` attribute of the service), and then have the `entrypoint` attribute of the service refer to the location of the script (within the container). If the setup doesn't need to be done within the service itself (e.g. when what is being set up is external to the service), you can create a special sidecar service with a special script/entrypoint that runs before the main service.

No matter how you start writing your Compose file, you should try to follow the guidelines laid out in the following subsections.

### Docker image version pinning (highly important!)
For the purposes of Compose stacks in `saphnet-compose-configs`, all Docker images should be pinned to specific SHA-256 digests, unless there is a specific reason not to. This is because SHA-256 digests are immutable (unchangeable) hashes that represent an exact build of an image; images behind a (Docker) repository or even its specific tags can change silently, but an image cannot change without its hash being different, so changing image version requires changes to Compose files, which are easily audited. Exact image version pinning allows for exact reproducibility (as images can't change silently), easy rollbacks, in the case of problems (due to this reproducibility), the ability to control when new versions are introduced (and make any configuration changes before doing so), and increased security, as immutability renders silent supply chain attacks impossible.

It is possible to use digests without version tags, and digests will take precedence over tags, but it is generally best practice to write both version tags and digests, so that humans can see the intent, that Dependabot can determine what images to upgrade to, and that the benefits of version pinning are maintained.

Any image name used in Compose stack services will use this format: `[HOST[:PORT]/][NAMESPACE/]REPOSITORY_NAME]:TAG][@DIGEST]`
- For `collabora/code:latest`, the namespace is `collabora`, the repository name is `code`, and the tag is `latest`; by default, the host and port are of the Docker Hub, and the digest will be inferred from the tag.
- For `ubuntu`, the repository name is `ubuntu`; the namespace is assumed to be the global namespace (`_`), the version tag is assumed to be `latest`, the host and port are assumed to be that of the Docker Hub, and the digest will be inferred from the assumed `latest` tag.
- For `ghcr.io/netbootxyz/netbootxyz:latest`, the registry is `ghcr.io`, the namespace is `netbootxyz`, the repository name is `netbootxyz`, and the version tag is `latest`; the port is assumed to be `443`, the port for HTTPS (Docker generally prefers using HTTPS), and the digest will be inferred from the tag.
- For `itzg/mc-proxy:java21@sha256:02803ab8390f89260e01693cc1fae519119fcae782d90e83ee3ea3ebd65567cc`, the namespace is `itzg`, the repository is `mc-proxy`, the tag is `java21`, and the digest is `sha256:02803ab8390f89260e01693cc1fae519119fcae782d90e83ee3ea3ebd65567cc`; the host and port are assumed to be that of the Docker Hub.

Before determining a specific digest hash to pick for an image, first consider the tag you want to use for your image, as this will determine what digest you will use, and determine how Dependabot will update these digests, to either keep it up to date with the tag or upgrade the tag itself.

Ideally, you would want to specify the most specific version tag that corresponds to the `latest` tag of the repository, like this (at the time of writing, `26.04.1.4.1` matches up with the `latest` tag of `collabora/code`):
```yaml
services:
  ... # Omitting for brevity
  wopi-server:
    image: collabora/code:26.04.1.4.1@sha256:75859dc9f9084d1877ce36cf96ec86600f495bade33289c9cbc27e0a0ee23b81
    ...
```

This allows for maximum communicability and the ability for Dependabot to update the tag to meet the latest version. To determine what tag to use, read the version tags of the page for the image repository on the Docker image registry website, and find the most specific version tag that has the same digest hashes as the image with the `latest` tag; certain image registries (e.g. ghcr.io) make this easier by listing all applicable tags for each digest, while others (e.g. the Docker Hub) require more manual scanning. Furthermore, when determining the specific digest to use, try to use the index digest instead of a platform-specific manifest digest; this allows the image to be used across multiple CPU architectures, and is the practice that Dependabot uses when updating images. 

Furthermore, if you want to stay up to date, but have to use a specific type of image (e.g. for a specific GPU), then this is also possible; again, do make sure your version tag's digest matches that of the latest version of the specific image type. Here is an example of this, for Immich's Machine Learning service:
```yaml
services:
  ... # Omitting for brevity
  immich-machine-learning:
    ...
    image: ghcr.io/immich-app/immich-machine-learning:v2.7.5-openvino@sha256:71cd5a681823c4b818f4b24b3f05816eccc3d085559e7615f695bde77e64f1f2
    ...
```

In this case, we use the `v2.7.5-openvino` tag; we use a specific version (`v2.7.5`) that corresponds to the latest version, and we specify a type, which is `openvino` in this case. Dependabot is still able to infer the intent of the tag, and update the tag and digest when new images come, if they are applicable; note that this depends on how the specific image repository tags their images, and it may not work for all repositories.

However, for certain image repositories, there may not exist any version-specific tags (e.g. `v0.1.0`), or the images behind the version tags are far behind in updates/functionality compared to the images behind the `latest` tag; in such cases, it is acceptable to use the `latest` tag, provided that a SHA-256 digest hash is present in the image name, like this:
```yaml
services:
  netbootxyz:
    image: ghcr.io/netbootxyz/netbootxyz:latest@sha256:39bb40c85d1f6e500b3df1871460f88609215735c224b234b9e6e4e849faf92b
    ... # Omitting for brevity
```

Even without a specific version specified, using the `latest` tag still gives Dependabot your intent in terms of upgrading the image, and it will still provide pull requests with image upgrades.

In certain cases, you may not want to use the latest version of an image, but rather stay within a release version (whether major or minor), whether for reasons of compatibility or stability; if that release version is still receiving updates, you may want to have Dependabot still upgrade your image when new updates come for it. In such a case, you can provide a version tag that specifies only the major (or even major AND minor) release version; as long as you do not provide the most specific type of version name possible, Dependabot will be able to provide image updates only for that version tag, and not change the version tag.

For example, here is an example of a Redis service sticking to version `8`, but nothing more specific, so that Dependabot doesn't upgrade the major version:
```yaml
services:
  ... # Omitting for brevity
  cache:
    image: redis:8@sha256:2838d5524559494f6f1cd66e97e76b200d64a633a8614200620755ed395daf32
    ...
```

This example allows for exact reproducibility, since Docker will only pull that specific image, and high stability while staying up to date, as Dependabot will ONLY provide updates to images that have the version tag for `8`.

If you already have a tag in mind for a Docker image, but want to know the current index digest (not a platform-specific digest) for it, you can use this command, if you have buildx installed (`IMAGE_NAME` is in the previously described format for Docker image names, sans the digest): `docker buildx imagetools inspect IMAGE_NAME --format "{{json .Manifest}}" | jq -r .digest`

### Structure
At the very minimum, a Compose stack directory will have a Compose YAML file (typically named `compose.yaml`) and a `README.md` file (if it is not a subdirectory of a subdirectory of `stacks`, in which case the README will be in the parent directory), similar to in this chart:
```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ compose.yaml
│   │   └─ README.md
│   └─ ...
└─ ...
```

In general, if there will only be one instance of a Compose stack, on one server, then the Compose YAML file should be named `compose.yaml`, since it is the default name of the latest Compose specification and Komodo will first look for Compose YAML files with that name,

However, you may have multiple Compose files for multiple servers. In such a case, you will want to have a base Compose YAML file with all common configuration, and a Compose YAML for each server. The files for each server should be named after the server they're intended to run on, so a file intended for `control-server` would be named `control-server.yaml`. As well, if it is expected for Komodo to provide both the base and server-specific file to Docker Compose, the base file should be named `compose.yaml`, and if the server-specific files, instead, refer to the base file by using the `extends` attribute, then the base file should be named `base.yaml`. A directory for a Compose stack intended for multiple servers would look like this:
```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ compose.yaml (or base.yaml)
│   │   ├─ SERVER-NAME.yaml
│   │   ├─ SERVER-NAME-2.yaml
│   │   └─ ...
│   └─ ...
└─ ...
```

You may have secrets that you may want to import with Komodo that are encrypted with SOPS. These secrets files should be per-server (for each server the Compose stack will run on), named after their respective servers, with a `.enc.env` extension (since they are supposed to be decrypted to become .env files); for example, a secrets file for a stack instance running on `docker-host-core` would be named `docker-host-core.enc.env`. Furthermore, all SOPS secrets files have to be placed within the `secrets` subdirectory of the Compose stack's directory, like in this chart:
```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ ...
│   │   ├─ secrets (optional)
│   │   │   ├─ SERVER-NAME.enc.env (SERVER-NAME stands in for a Server resource's name)
│   │   │   ├─ SERVER-NAME-2.enc.env
│   │   │   └─ ...
│   │   ├─ compose.yaml (or base.yaml)
│   │   └─ ...
│   └─ ...
└─ ...
```

If you have any non-Compose files (e.g. application-specific config files) that you want to provide to the services in the Compose stacks, you are able to place them anywhere within the Compose stack's directory. There are no restrictions, besides not being named after any Compose YAML files or `README.md`, or being in the `secrets` subdirectory, but it is best practice to categorize and group files into specific subdirectories, if it provides extra clarity. Here is the chart of an example of such a Compose stack directory:
```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ secrets
│   │   │   └─ ...
│   │   ├─ (You can categorize config and other files into subdirectories, in any structure you like, for better organization)
│   │   │   ├─ Config file (e.g. init-script.sh or nginx.conf)
│   │   │   ├─ (Potentially, more config files)
│   │   │   └─ ...
│   │   ├─ (You can also place config files in the main stack directory, too)
│   │   ├─ compose.yaml (or a set of other Compose YAML files)
│   │   └─ ...
│   └─ ...
└─ ...
```

In general, the structure of a Compose stack directory is quite flexible, as long as the Compose YAML files follow the right naming standards, there is a README, and the secrets subdirectory sticks to the specified structure. However, do make sure that the references to other files in Compose YAML files are relative (not absolute) and match where the other files actually are, and that each non-Compose config file is listed in the Komodo Stack resource to be tracked.

### Formatting
*As mentioned previously, make sure to follow the standards that are [listed in the latest Compose specification](https://github.com/compose-spec/compose-spec)!*

In general, all Compose YAML files should keep to a consistent formatting style, which this section will list out. Not being consistent won't cause any technical issues, but note that any and all inconsistencies do pile up, resulting in increased friction when trying to create and maintain code for this repository.

#### Spacing, indentation, line length
Indentation of all Compose YAML files should use spaces, and should be done with 2 spaces at a time. For spacing, single empty lines should exist between all top-level attributes (e.g. `services` and `volumes`), and between the configurations of all services (in `services`); it is not necessary to add spaces between the attributes (or subattributes) of services themselves, however, unless needed to separate groups of configuration lines (e.g. labels). For line length, there is no hard limit, as certain lines may need to be much longer than others (e.g. for scripts), but as a general rule, each Compose YAML file should try to have a consistent length limit for all of its lines; if unsure where to start, try to avoid more than 160 characters per line (ideally, each line is up to 80 characters in length). 

#### Ordering of keys
All top-level properties for Compose YAML files should be listed in this order ([service-keys-order-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/service-keys-order-rule.md)): all `x-`-prefixed attributes (in alphabetical order), `version`, `name`, `include`, `services`, `networks`, `volumes`, `secrets`, `configs`

All keys of a service should be listed in this order ([service-keys-order-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/service-keys-order-rule.md), all italicized keys are keys that were not originally in the list): *extends*, image, build, container_name, depends_on, volumes, volumes_from, configs, secrets, environment, env_file, ports, networks, network_mode, extra_hosts, command, entrypoint, working_dir, restart, healthcheck, logging, labels, *pid*, user, isolation, cap_add, devices, expose, sysctls

Instead of ordering services in `services` in alphabetical order, however, this repository will have its services in each Compose YAML file be listed in order of importance (or significance), from most relevant to least relevant (for the main application(s) for which the stack exists).

#### Choosing between sequences and dictionaries (e.g. environment variables)
For certain keys in services, like labels and environment variables, you may have a choice between using sequences of strings, and dictionaries, for the key.

This is what using sequences of strings would look like for these keys:
```yaml
services:
  example:
    ...
    environment:
      - KEY_ID=0
    labels:
      - example.examplelabel=true
```

And this is what it looks like to use dictionaries, instead (do note that the values below are quoted so that they are interpreted as strings):
```yaml
services:
  example:
    ...
    environment:
      KEY_ID: "0"
    labels:
      example.examplelabel: "true"
```

For these keys, it is preferred to use dictionaries whenever possible. When using IDEs, lines using dictionaries are easier to parse and read, and, more importantly, using dictionaries allows us to use YAML fragments as values for specific labels/environment variables, as we are unable to combine fragment values and strings:
```yaml
x-common:
  SERVER_NAME: &server-name "example-server"
  SERVER_DOMAIN: &server-domain "example.com"

services:
  example:
    ...
    environment:
      SERVER_NAME: *server-name
    labels:
      reverse-proxy.hostname: *server-domain
``` 

#### Naming
Try to use descriptive names (names that don't require many comments to explain) whenever possible, and if there is a choice between picking a shorter and longer name, prefer the longer name.

Environment variables (both environment variables passed to Docker Compose via Komodo, and environment variables given to containers) should be named in screaming snake case (e.g. `SERVER_NAME`).

Any keys named under top-level `x-properties` properties (any property that starts with `x-`), which do not have values that are dictionaries, should also be given snake case (e.g. `MYSQL_PASSWORD`); if the keys do represent dictionaries, then they can simply use normal (lowercase) snake case, while their child keys should be in screaming snake case. However, YAML fragment names should be in kebab case (e.g. `mysql-password` in `&mysql-password`).

Services, networks, volumes, configs, and secrets should generally be in kebab case, as well (e.g. `n8n-runner`); note, that in practice, networks are named in (lowercase) snake case (e.g. `web_bridge`).

No matter the naming convention of the Compose YAML file being worked on, however, if it does break any of these guidelines, err in favor of maintaining consistency with what already exists in the file.

#### Using quotes for values
When listing volume mounts under the `volumes` key of a service, avoid using quotes, as this may lead to errors with Docker. The entries within `volumes`, for any service, should look like this ([no-quotes-in-volumes-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/no-quotes-in-volumes-rule.md)):
```yaml
services:
  example:
    ...
    volumes:
      - /example/path/on/host:/path/on/container
```

Conversely, when listing port mappings under the `ports` key of a service, you should always use quotes, to avoid YAML parsing issues with numbers, like this ([require-quotes-in-ports-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/require-quotes-in-ports-rule.md)):
```yaml
services:
  example:
    ...
    ports:
      - "8043:80" # 8043 on the host, 80 on the container
```

In any case, when referring to environment variables provided to the Docker Compose command (anywhere in the Compose YAML file that will be interpreted), if the environment variable is being used for a value to a key that expects a string (e.g. labels and environment variables), try to ensure that it, or the entire string that it may be a part of, are surrounded in quotes to ensure that the value is ALWAYS parsed as a string, like in this example:
```yaml
services:
  example:
    ...
    environment:
      ALWAYS_USE_EXAMPLE_OPTION: "true"
```

In this example, the application may expect the value of "ALWAYS_USE_EXAMPLE_OPTION" to be "true" or "false", as environment variables are always strings. However, if there were no quotes around `true`, then the YAML parser will interpret it as a YAML boolean, and when the value is evaluated to create an environment variable from, it may be something unexpected, like `1` instead. Quotes are generally useful when defining strings, to reduce any ambiguity in such cases.

#### Note on the `version` key

*More on the rationale: [no-version-field-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/no-version-field-rule.md)*

Avoid specifying the `version` key (e.g. `version: '3.8'`) among the top-level properties of a Compose YAML file, as it is a deprecated key in current versions of Compose; current versions of Compose automatically determine the version of a file, based on the features used. 

#### Miscellaneous
When it comes to ordering labels and environment variables within a service, there are no exact guidelines for this repository: the main priority, here, is for ease of reading, so using alphabetical order or visually separating lines into categorized groups, may be helpful in certain scenarios.

### Arguments (for the program being run as the entrypoint)
- again, it's like passing arguments to progrma itself! Just make sure it's in same order you do it manually
- do write disclaimer about entrypoint vs cmd, where entrypoint is the base command always run by container (unless overwritten), and cmd is the arguments attached in front of the base command, even if multiple arguments in entrypoint already (add note about there's default, so being careful if docker image already defines cmds)
- if unsure what arguments to use, check the entrypoint command and see what it accepts
- write note on splitting on whitespace! if whitespace included in line, it's like it was wrapped in quotes
- can be regular string or a sequence of strings (exec form) (it is ordered) 
  - add note about regular string (shell form) being automatically wrapped with /bin/sh

```yaml
services:
  database:
    ... # Omitting for brevity
    command: --default-authentication-plugin=mysql_native_password
    ...
```

```yaml
services:
  traefik: # Reverse proxy, with dashboard enabled
    ... # Omitting for brevity
    command:
      # Entrypoints
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      ...
```

### Environment variables, fragments, and overall plumbing
- sometimes, you may have values that you probably don't want to have in plaintext, like secrets, but need to find a way to have the container have those values when deployed too
- sometimes, you may want to provide options and values only determined at deploy-time, to allow for flexibility when Komodo deploys them (like multi-server stack setups)
- on other hand, maybe you specify a certain value many many times across stack, and you want central place to define them, since error-prone to change many places at once
- or maybe you just want a value that you may change often to be easy to find and change
- for either of these options, you can use environment variables and fragments, sometimes even both combined!
- environment variables are values in files, that are automatically replaced by docker compose command when reading the file, with the environment variables that docker compose has access to
- do add note on quoting things that may be interpreted as not strings (just do it in case), since YAML parser may be confused and give wrong value, and environment variables are only strings
- also, for environment variables, try to list them all in the first lines of comments, try to be consistent with README
- fragments are basically reusable blocks, often defined in x- something (e.g. x-common), that are defined once, and then replace whatever refers to those fragments, great for reducing boilerplate and having streamlined places for sources of truth
- explain how environment variables can basically replace literally anywhere in compose file, not just environment vars
- and then explain fragments, how they can replace both individual keys but also sections
  - note even fragments can be sub attributes of other attributes that are fragments too

```yaml
# Environment variables to set:
# - MAIL_PASSWORD
# - RUSTIC_S3_REGION
# - RUSTIC_S3_ACCESS_KEY_ID
# - RUSTIC_S3_SECRET_ACCESS_KEY
# - RUSTIC_S3_BUCKET
# - RUSTIC_S3_ENDPOINT (include "https://"!)
# - HASHIDS_SALT (should be 20 characters, to generate this, run "head -c20 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9/.' | head -c20")
```

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

```yaml
x-common:
  ... # Omitting for brevity
  panel: &panel-environment
    APP_URL: "https://pterodactyl.int.saphnet.xyz"
    APP_TIMEZONE: *timezone
    ...
  mail: &mail-environment
    MAIL_FROM: "homelab@saphnet.xyz"
    MAIL_DRIVER: "smtp"
    ...
  # S3-based backup
  backup: &backup-environment
    APP_BACKUP_DRIVER: rustic_s3
    RUSTIC_S3_FORCE_PATH_STYLE: "true"
    ...

services:
  ...
  panel:
    ...
    environment:
      <<: [*panel-environment, *mail-environment, *backup-environment]
      DB_PASSWORD: *db-password
      APP_ENV: "production"
      ...
```

```yaml
x-common:
  ... # Omitting for brevity
  panel: &panel-environment
    ...
    HASHIDS_SALT: "${HASHIDS_SALT}"
    ...
  mail: &mail-environment
    ...
    MAIL_PASSWORD: "${MAIL_PASSWORD}"
    ...
  backup: &backup-environment
    ...
    RUSTIC_S3_REGION: "${RUSTIC_S3_REGION}"
    RUSTIC_S3_ACCESS_KEY_ID: "${RUSTIC_S3_ACCESS_KEY_ID}"
    RUSTIC_S3_SECRET_ACCESS_KEY: "${RUSTIC_S3_SECRET_ACCESS_KEY}"
    RUSTIC_S3_BUCKET: "${RUSTIC_S3_BUCKET}"
    RUSTIC_S3_ENDPOINT: "${RUSTIC_S3_ENDPOINT}"

services:
  ...
  
  panel:
    ...
    environment:
      <<: [*panel-environment, *mail-environment, *backup-environment]
      DB_PASSWORD: *db-password
```

#### On .env files (vs regular environment variables)
- there are two ways to import environment variables: referring to them directly in docker compose
  - but also using env_file, to provide list of files with environment variables to give DIRECTLY
- komodo-provided environment variables are provided in .env by default (but this can be changed too, with env_file_path)
- can also provide it other files
- if using secrets, can also do environment variable of path, like SOPS_SECRETS_PATH
- allows compose file not to deal with contents of variables, but also doing it this way means it can't use it for non-env vars, also can't control what is imported

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

#### Secrets
- note about them being in special secrets subdirectory, being .enc.env (env format)
- write about secrets being per-server, with .sops.yaml mapping file names to what keys are used
  - probably have an example map here
- also note that the compose file doesn't interact with them, komodo reads the secrets and then makes them environment variables for docker compose to read and then pass to container as compose file sees fit
  - distinction only matters in komodo, since komodo setup handles secrets differently, in compose, only see environment variables, not where they came from
- consider about how secrets imported, can be as individual environment variable that compose needs to be aware of, or as whole .env file to be given to container
  - each has tradeoffs!
  - first method is simpler in komodo, and environment variables can be used across compose in any way (outside of container env), but every time new environment variable added to image, compose file must be aware of it, so can lead to double work
  - second method allows to define environment vars only once in one file, but can't be used easily outside specific container, also locks you in somewhat into only using secrets by passing it directly to container (can't easily be used in compose file itself, unless weird custom command), and not very granular
- talk about how each method requires different formatting, parsing, so either dumb properties style or bash style that may require escaping (though just use single quotes)

```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ secrets
│   │   │   ├─ SERVER-NAME.enc.env (SERVER-NAME stands in for a Server resource's name)
│   │   │   ├─ SERVER-NAME-2.enc.env (if multiple servers)
│   │   │   └─ ...
│   │   └─ compose.yaml, ...
│   └─ ...
├─ .sops.yaml
└─ ...
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

#### On VPN containers
- in certain case, you want container to connect to certain location or have certain IP
- this is what vpn container is for
- vpn container is special container that handles connections, sets up the routing with the kernel too (so need special capabilities, devices, config)
- its network space is also the network space that the container using the vpn uses, so any network setup should not be done with that container, but with vpn container
- on container using vpn, make sure it waits for vpn container to be ready before starting, and that its network_mode is vpn
- do mention that gluetun is probably what you want

```yaml
services:
  ... # Omitting for brevity
  vpn:
    image: qmcgaw/gluetun...
    container_name: deluge-vpn
    environment:
      VPN_SERVICE_PROVIDER: nordvpn
      VPN_TYPE: openvpn
      ...
      OPENVPN_USER: "${OPENVPN_USER}"
      OPENVPN_PASSWORD: "${OPENVPN_PASSWORD}"
      SERVER_HOSTNAMES: "${CONNECT}.nordvpn.com"
    ports:
      ...
      - "58846:58846"
    networks:
      - web_bridge
    labels:
      traefik.enable: "true"
      traefik.http.routers.seedbox.rule: Host(`seedbox.int.saphnet.xyz`)
      traefik.http.routers.seedbox.entrypoints: websecure
      traefik.http.routers.seedbox.tls: "true"
      traefik.http.routers.seedbox.tls.certresolver: letsencrypt
      traefik.http.routers.seedbox.tls.domains[0].main: seedbox.int.saphnet.xyz
      traefik.http.routers.seedbox.service: seedbox-svc
      traefik.http.services.seedbox-svc.loadBalancer.server.port: "8112"
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    expose:
      - "8112"
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=1 # Recomended if using ipv4 only
    ...

  deluge:
    ...
    depends_on:
      vpn:
        condition: service_healthy
    network_mode: service:vpn
    ...
```

### Volumes, mounting
- docker containers are ephemeral, meaning that any data written within their internal file systems is gone when container is deleted (and it will be deleted on updates)
- may have data that you want to keep across containers (be persistent), that isn't configuration or can be provided by IaC, like databases, records, media, etc
- volumes provide safe place, decoupled from container, to store and access data, docker manages them
- volumes typically on local storage
- furthermore, multiple containers can use volume at once
- refer to volumes with their names, and you mount them to specific locations within container's file system
- only need to have key in volumes attribute for volume, but you can do more, like access volumes external to stack
- can also have volumes that aren't docker but are other things through driver, so like NFS
- you can use directories on host instead of docker volumes, but not super portable and very reliant on operating system environment on which komodo runs, but may be needed to docker volumes don't work

```yaml
volumes:
  guac-db-data:
```

```yaml
services:
  guacdb:
    ... # Omitting for brevity
    volumes:
      - guac-db-data:/var/lib/mysql
    ...
```

```yaml
services:
  guacdb:
    ... # Omitting for brevity
    volumes:
      - /directory/on/host:/var/lib/mysql
    ...
```

#### Mounting non-Compose config files (and Compose files not directly opened by Komodo!)
- Docker Compose only takes in compose files, and while you can do a lot with them, you may still need to provide other configuration files, so volumes feature can be used here, mount files on repo to specific location in container
- remember that containers don't have access to files unless given, and it has to be mounted in specific places (which can be to our advantage, since we can organize our stacks directory how we want, and we can map it to how program expects it)
- stuff about making sure relative to root of stack directory
- note about read-only, to avoid potential issues, since it is IaC

```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ secrets
│   │   │   └─ ...
│   │   ├─ (You can categorize config and other files into subdirectories, in any structure you like, for better organization)
│   │   │   ├─ Config file (e.g. init-script.sh or nginx.conf)
│   │   │   ├─ (Potentially, more config files)
│   │   │   └─ ...
│   │   ├─ (You can also place config files in the main stack directory, too)
│   │   ├─ compose.yaml (or a set of other Compose YAML files)
│   │   └─ ...
│   └─ ...
└─ ...
```

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
- for certain persistent storage needs, may not want to use a normal volume
- normal volumes are stored locally (on the host)
  - host may not have enough storage
  - may just want to use the capacity (and features) of a NAS
  - maybe data is already on NAS, or want the data to outlast stack setup
  - maybe you just don't want the data on the host at all
- for this, can read and write data on a NAS, and use NFS!
- make sure on NAS, that volume works, that an NFS share is there, and that the hostname of the docker host with the stack is allowed to connect to it (NFS doesn't have much security, so try to at least limit the IP addresses that can access it)
  - note: for truenas, format may be "/mnt/DATAPOOL/DATASET[/SUBDATASET][/SUBDIR]"
- describe the volume part, make sure to describe the boilerplate, and why it exists, and then also try to push towards nfsvers=4
- anyway, in the services, it just acts like any volumes
- also you can have as many volumes as you like that reference the same directory on the NAS (or their subdirectories)
- note about if NAS is down, the service will stall (lock up) when accessing file on NAS until NAS goes back up, so be careful

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

### Device mounting (e.g. GPUs)
- hardware devices? can be easily added to containers, just provide their device location (linux stuff)
- for GPUs, pretty simple, if not using nvidia, can just add /dev/dri

```yaml
services:
  vertd:
    ... # Omitting for brevity
    devices:
      - /dev/dri
    ...
```

### Traefik
- redirect them to traefik README
- still, give them a basic explainer on what they need for bare minimum traefik setup
- make sure traefik exists on server that stack is running on
- make sure it's connected to `web_bridge` network, since that is what traefik uses to connect
- traefik mostly works with labels
  - need to have enable
  - then a rule linking what hostname to connect it to, other things
  - then a service so it knows how to redirect traffic

*More on how to configure Traefik*: [Traefik README](stacks/traefik/README.md)

```yaml
services:
  jellyfin:
    image: ... # Truncating here
    networks:
      - web_bridge # Traefik, in this instance, connects to services via the web_bridge network, so we need to be reachable through it
    labels:
      traefik.enable: true
      traefik.http.routers.jellyfin.rule: Host(`jellyfin.media.int.saphnet.xyz`)
      traefik.http.routers.jellyfin.entrypoints: websecure
      traefik.http.routers.jellyfin.tls: true
      traefik.http.routers.jellyfin.tls.certresolver: letsencrypt
      ## HTTP Service
      traefik.http.routers.jellyfin.service: jellyfin-svc
      traefik.http.services.jellyfin-svc.loadBalancer.server.port: "8096"
    ... # Again, truncating
    restart: unless-stopped
```

### Other custom functionality (entrypoints, scripts, init services)
- Do add TODO note on this: https://docs.docker.com/compose/how-tos/init-containers
- sometimes, before container runs, or while container runs, may need to do something so it can do its job properly that can't be easily done with default functionality or execution flow
  - sometimes it needs to do stuff with files, databases, networks, create initial data, etc
- For this, can use entrypoints, scripts (to feed into container if it supports that), and init containers
- Entrypoints pretty simple since it is first command that container runs, but do make sure to investigate dockerfile so you know how to go back to regular function
- Alternatively, can have init container with image of your choosing that does stuff, you can have main container wait for it to run, though this only works for stuff that is external to container (e.g. volumes, networks)
- Either way, if script a bit lengthy, probably good idea to have it be separate file and mount it with volume
- If image supports it, you can also mount script files with volumes, and have the container run the script alongside its own things

```yaml
services:
  app:
    ... # Omitting for brevity
  wopi_server:
    image: collabora/code...
    ...
    entrypoint:
      - /bin/bash
      - -c
      - |
        curl -o /usr/share/coolwsd/browser/dist/branding-desktop.css https://gist.githubusercontent.com/mickael-kerjean/bc1f57cd312cf04731d30185cc4e7ba2/raw/d706dcdf23c21441e5af289d871b33defc2770ea/destop.css
        /bin/su -s /bin/bash -c '/start-collabora-online.sh' cool
```

```yaml
services:
  postgres:
    ... # Omitting for brevity
    volumes:
      ...
      - ./init-data.sh:/docker-entrypoint-initdb.d/init-data.sh
    ...
```

```bash
#!/bin/bash
set -e;


if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
		GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};
		GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
	EOSQL
else
	echo "SETUP INFO: No Environment variables given!"
fi
```

```yaml
services:
  example-service: # Has volume that may need to be set up first
    ... # Omitting for brevity
    depends-on:
      init-helper: # Waits for init-helper to exit before running
        condition: service_completed_completely
    ...
    volumes:
      - example-service-data:/var/lib/example
    ...
  init-helper:
    image: alpine
    ...
    volumes:
      - example-service-data:/config
    ...
    entrypoint:
      - /bin/bash
      - -c
      # This is a multi-line Bash script, through which you can run what the image offers
      # If you need a lot of lines, you might want to mount a script and have that be the entrypoint
      - |
        mkdir -p /config/data
        if [ ! -f /config/data/secret.txt ]; then
          tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 > /config/data/secret.txt
        fi

volumes:
  example-service-data:
```

### Writing stacks to be run across multiple servers
- a compose stack is just a blueprint, still needs to be run on server
- in fact, you can deploy a compose stack as many times as you want
- depending on applications, using the same file as-is may work
- in some cases, may want to distinguish the instances or give them different data/arguments
  - if simple enough, can just make them environment variables (for docker compose to interpolate) and have komodo feed them per Stack
- however, setup may require more complex setup that can't just use env vars, like different structures and such
- in that case, can have different compose stack files in stack dir
  - however, please have them share as much as possible
    - exist two ways to do this
      - can have a base file and a server-specific file that komodo will specifically read (be given that) and merge
      - can also have a file that serves as a template, and then server-specific file that directly references the service in that file, and extend and merge with its own data, komodo does not need to know about base file
- first method
  - komodo just merges things
  - if key-value pairs, will just merge them recursively
    - if any conflicting pairs though (whose values aren't just dictionaries or sequences), then will be overwritten by file specified last
    - if sequence, will be appended in order of files
    - however, shell commands, entrypoints, healthcheck: test will be overwritten
    - can use !reset and !override if stuff
- second method
  - komodo doesn't know about the file, docker compose will handle it when reading the file that komodo gives
  - less files to handle on komodo itself, but extends part is only per service and object, anything that extended object references will not be imported unless specified too in file komodo uses
  - again, importing file overrides of imported file

```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ ...
│   │   ├─ secrets (optional)
│   │   │   ├─ SERVER-NAME.enc.env (SERVER-NAME stands in for a Server resource's name)
│   │   │   ├─ SERVER-NAME-2.enc.env
│   │   │   └─ ...
│   │   ├─ compose.yaml
│   │   ├─ SERVER-NAME.yaml
│   │   ├─ SERVER-NAME-2.yaml
│   │   └─ ...
│   └─ ...
└─ ...
```

```
Repository root (./.)
│
├─ ...
├─ stacks
│   ├─ (Your stack)
│   │   ├─ ...
│   │   ├─ secrets (optional)
│   │   │   ├─ SERVER-NAME.enc.env (SERVER-NAME stands in for a Server resource's name)
│   │   │   ├─ SERVER-NAME-2.enc.env
│   │   │   └─ ...
│   │   ├─ base.yaml
│   │   ├─ SERVER-NAME.yaml
│   │   ├─ SERVER-NAME-2.yaml
│   │   └─ ...
│   └─ ...
└─ ...
```

```yaml
# To be run, and merged, with another host-specific file (e.g. control-server.yaml)
# Example command:
# docker compose -f base.yaml -f control-server.yaml up

x-common:
  TIMEZONE: &timezone "America/Los_Angeles"

services:
  docker-volume-rclone: &docker-volume-rclone # Is base service
    image: ghcr.io/anarchobooleanism/docker-volume-rclone:v0.1.1@sha256:9944901a7f4b59173725591893f587681b5caa85f4da572baa43bad669bc2f6c
    volumes:
      - /var/lib/docker/volumes:/volumes:ro
      - nfs-target:/volumes-clone
    environment: &environment
      # Set TARGET_SUBDIR_NAME here
      # Set VOLUME_NAMES here, is space-delimited string, use ">-"
      RUN_ON_STARTUP: "false"
      CRON_ARGUMENTS: "0 */4 * * *" # At minute 0, every 4 hours
      # RCLONE_OPTIONS:
      TZ: *timezone

volumes:
  nfs-target:
    driver_opts:
      type: "nfs"
      o: "addr=nas1.int-net.saphnet.xyz,nolock,soft,rw,nfsvers=4"
      device: ":/mnt/saphnet-nas1c/docker-volume-backups"
```

```yaml
# To be run, and merged, with the base file
# Example command:
# docker compose -f base.yaml -f control-server.yaml up

services:
  docker-volume-rclone:
    environment:
      TARGET_SUBDIR_NAME: control-server
      VOLUME_NAMES: >-
        komodo_mongo-config
        komodo_mongo-data
```

```yaml
x-common:
  TIMEZONE: &timezone "America/Los_Angeles"

services:
  docker-volume-rclone: &docker-volume-rclone # Is base service
    image: ghcr.io/anarchobooleanism/docker-volume-rclone:v0.1.1@sha256:9944901a7f4b59173725591893f587681b5caa85f4da572baa43bad669bc2f6c
    volumes:
      - /var/lib/docker/volumes:/volumes:ro
      - nfs-target:/volumes-clone
    environment: &environment
      RUN_ON_STARTUP: "false"
      CRON_ARGUMENTS: "0 */4 * * *"
      TZ: *timezone
      # These environment variables below are from control-server.yaml!
      TARGET_SUBDIR_NAME: control-server
      VOLUME_NAMES: >-
        komodo_mongo-config
        komodo_mongo-data

volumes:
  nfs-target:
    driver_opts:
      type: "nfs"
      o: "addr=nas1.int-net.saphnet.xyz,nolock,soft,rw,nfsvers=4"
      device: ":/mnt/saphnet-nas1c/docker-volume-backups"
```

```yaml
# NOTE: If you want this to be accessible via Traefik, have a separate Compose file that refers to
# this file that has the labels included.
# This is the generic base version, with no labels. This can be run as-is, standalone.

services:
  glances:
    image: nicolargo/glances:4.5.5@sha256:9ac5de7debffb1e5746654585daaf1d23179ea91fbdfd4c25a7a17945d9c74bf
    container_name: glances
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      # Uncomment the below line if you want glances to display host OS detail instead of container's
      - /etc/os-release:/etc/os-release:ro
      - /etc/hostname:/etc/hostname:ro
    environment:
      GLANCES_OPT: "-w"
    # ports:
    #   - "61208:61208"
    network_mode: host # Make sure to set firewall rules accordingly!
    restart: unless-stopped
    pid: host
```

```yaml
# No need to run this AND compose.yaml, this file imports it by default

services:
  glances:
    extends:
      file: ./compose.yaml
      service: glances
    labels:
      traefik.enable: "true"
      traefik.http.routers.glances.rule: Host(`glances.docker-host-core.int.saphnet.xyz`)
      traefik.http.routers.glances.entrypoints: websecure
      traefik.http.routers.glances.tls: "true"
      traefik.http.routers.glances.tls.certresolver: letsencrypt
      traefik.http.routers.glances.tls.domains[0].main: docker-host-core.int.saphnet.xyz
      traefik.http.routers.glances.tls.domains[0].sans: "*.docker-host-core.int.saphnet.xyz"
      traefik.http.routers.glances.service: glances-svc
      traefik.http.services.glances-svc.loadBalancer.server.url: "http://host.docker.internal:61208"
```


```yaml
services:
  glances:
    image: nicolargo/glances:4.5.5@sha256:9ac5de7debffb1e5746654585daaf1d23179ea91fbdfd4c25a7a17945d9c74bf
    container_name: glances
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      # Uncomment the below line if you want glances to display host OS detail instead of container's
      - /etc/os-release:/etc/os-release:ro
      - /etc/hostname:/etc/hostname:ro
    environment:
      GLANCES_OPT: "-w"
    # ports:
    #   - "61208:61208"
    network_mode: host # Make sure to set firewall rules accordingly!
    restart: unless-stopped
    labels:
      traefik.enable: "true"
      traefik.http.routers.glances.rule: Host(`glances.docker-host-core.int.saphnet.xyz`)
      traefik.http.routers.glances.entrypoints: websecure
      traefik.http.routers.glances.tls: "true"
      traefik.http.routers.glances.tls.certresolver: letsencrypt
      traefik.http.routers.glances.tls.domains[0].main: docker-host-core.int.saphnet.xyz
      traefik.http.routers.glances.tls.domains[0].sans: "*.docker-host-core.int.saphnet.xyz"
      traefik.http.routers.glances.service: glances-svc
      traefik.http.services.glances-svc.loadBalancer.server.url: "http://host.docker.internal:61208"
    pid: host
```

### Writing a README
- tldr: basically write for someone who knows nothing about the stack, but wants to instantiate something for a specific server, though assume they know docker and such, give them enough to get something from scratch
- give a quick description, this will be used in the Stack description too
- give notes and warnings about things to watch out, dependencies, etc
- describe environment variables to pass
- if stack requires manual work after deploying, guide them through all the steps, the more they can copy and paste, the better

```markdown
When deploying, make sure to set these environment variables with your secrets:
- `VELOCITY_FORWARDING_SECRET` - The forwarding secret to use with Velocity, for the purposes of authentication
- `RCON_PASSWORD` - The password to login into Velocity's RCON server with (**IMPORTANT**: avoid using `#` in your password!)
- `SFTP_PASSWORD` - The password to login into the SFTP server as `velocity-user` with
- `TAILSCALE_IP` - For the SFTP and RCON servers, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)
```

## Setting up Stacks in Komodo resource file
- add note on making sure any changes to compose, non-compose config, and environment variables ARE reflected in this! since komodo is what controls stuff and redeploys
- Again, Compose stacks are just blueprints that are one step away from deployment, but something needs to deploy them and provide things like environment variables, etc
- Komodo stack resources are what this is for, describes a Stack, the resource describing what the Compose stack looks like and how its managed
- for our repo, stacks are added to resource file of the server it goes on
- lot of boilerplate, which just means it can easily be updated and best practices for redeploying, as well as describing the repo
- but also describes what files to give to docker compose, also environment variables, and how SOPS will provide secrets
- since Komodo is what checks and redeploys, also want to provide it things like extra config files to track and monitor, so that changes outside compose files change things too
- do add note on adding things to resource sync too
- again, make sure you add stack in alphabetical order

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

```toml
## Stack-related procedures

[[procedure]]
name = "vps1_redeploy-changed"
description = "A procedure that redeploys all IaC stacks that have had changes to their config or config files, for vps1."
tags = ["redeploy-changed", "iac"]

[[procedure.config.stage]]
name = "Stage 1"
enabled = true
executions = [ # Make sure to give all the names of all stacks here!
  { execution.type = "BatchDeployStackIfChanged", execution.params.pattern = """
docker-proxy-vps1
glances-vps1 <- This is where our glances-vps1 Stack is listed, so that the procedure knows to update it too
traefik-vps1
velocity-vps1
""", enabled = true }
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
- your stack files may expect environment variables to be provided when docker compose reads them
- environment, a multi string "key = value" entry in stack.config is where you can define these (for non-secrets; sops is handled differently)
- komodo reads these and provides them to docker compose for it to process (and pass it to container depending on stack config)
- komodo saves these to ".env" (in current working dir) by default (but this can be changed too, with env_file_path), but can also refer to them in stack files being imported and run
- unlike regular bash, you can put spaces around = symbol
- however, note that single quote makes sure things are literal, since things WILL be parsed, if not using single quotes, then please escape $ with backslashes
- generally good practice to use single quotes
- also, you can use komodo variables here too (covered later)

```toml
[[stack]]
name = "example-stack"
... # Omitting for brevity
[stack.config]
...
environment = """
EXAMPLE_VAR_1 = 'foobar'
EXAMPLE_VAR_2 = '[[KOMODO_EXAMPLE_VAR_1]]'
EXAMPLE_VAR_3 = 'abc$d1234$_5'
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
- if, across stacks, see yourself reusing same values in environment variables, may want to use komodo variables
- komodo variables serve as single source of truth, write that and you update everything
- they can be for non-secrets and secrets too
- variables can be written in saphnet-komodo, for more iac everywhere
- to use them, basically write their name wrapped in double brackets
- again, convention is to use all caps, screaming snake case
- also, good idea to wrap them in quotes to avoid potential parsing errors

```toml
# immich
[[stack]]
name = "immich"
... # Omitting for brevity
[stack.config]
...
environment = """
TAILSCALE_IP = '[[TAILSCALE_IP_PVE3]]'
"""
```

## Setting up new hosts/servers
- for setting up new Server resource for new server, after setting up stuff in saphnet-komodo, saphnet-komodo will expect this file, and that it contains these
- file name generally is server-name.toml, it is komodo resource file
- as well, you should have entry in .sops.yaml for server
  - describe how to add it, and generate key (make sure the key is passed to komodo periphery when it runs, like in compose and nixos config)
- redeploy-changed procedure is bare minimum (make sure name matches server name), and is in exact format as described (saphnet-komodo procedure saphnet-run-iac-stack-sync designed to run all executions that end in _redeploy-changed)
- in redeploy-changed, make sure list of stacks in execution pattern matches names of all stacks defined here
- after that, is just list of stacks (each stack written like in the guide above), in alphabetical order, separated with "##" and newlines before and after

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