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
- **Does the application require multiple commands, extra setup, etc. before running?** If so, modify the `entrypoint` attribute of the service to start a shell (e.g. `/bin/bash`), and then, under the `command` attribute of the service, specify the commands that are needed to perform the extra setup, and finally, specify the command that will run the main application. If the script is lengthy, you can have it as a separate script file that then gets mounted to the service (under the `volumes` attribute of the service), and then have the `entrypoint` attribute of the service refer to the location of the script (within the container). If the setup doesn't need to be done within the service itself (e.g. when what is being set up is external to the service), you can create a special sidecar service with a special script/entrypoint that runs before the main service.

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

All keys of a service should be listed in this order ([service-keys-order-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/service-keys-order-rule.md)): *`extends`*, `image`, `build`, `container_name`, `depends_on`, `volumes`, `volumes_from`, `configs`, `secrets`, `environment`, `env_file`, `ports`, `networks`, `network_mode`, `extra_hosts`, `command`, `entrypoint`, `working_dir`, `restart`, `healthcheck`, `logging`, `labels`, *`pid`*, `user`, `isolation`, `cap_add`, `devices`, `expose`, `sysctls` (all italicized keys are keys that were not originally in the list)

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

When defining environment variables and labels, which always are supposed to be strings, try to use quotes for strings that may possible be interpreted as non-strings (e.g. booleans and integers). It may be possible that a YAML parser may incorrectly parse such value, if non-voted, as non-string literals, and cause unexpected behavior where the value of the environment variable/label is different to what was originally written. Here is an example of this being used for a Compose stack file:
```yaml
services:
  example:
    ...
    environment:
      ALWAYS_USE_EXAMPLE_OPTION: "true"
```

For this example, the application may expect the value of "ALWAYS_USE_EXAMPLE_OPTION" to be `true` or `false` (as strings), as environment variables are always strings. However, if there were no quotes around `true`, then the YAML parser will interpret it as a YAML boolean, and when the value is evaluated to create an environment variable from, it may be something unexpected, like `1` instead. 

In any case, when referring to environment variables provided to the Docker Compose command (anywhere in the Compose YAML file that will be interpreted), if the environment variable is being used for a value to a key that expects a string (e.g. labels and environment variables), try to ensure that it, or the entire string that it may be a part of, are surrounded in quotes to ensure that the value is *always* parsed as a string, like in this example:
```yaml
services:
  example:
    ...
    environment:
      SERVER_ID: "${SERVER_ID}"
```

The application in the above example service will always treat the `SERVER_ID` environment variable as environment variables are always strings. However, if there were no quotes around `${SERVER_ID}`, there may be some edge case where `SERVER_ID` (on Docker Compose's side) may look like a boolean or a number (e.g. `true` or `15`) that would cause a YAML parser to interpret it as a non-string literal, leading to the resulting value of the environment variable being something unexpected, instead, such as `1` when `SERVER_ID` is `true`. Quotes are generally useful when defining strings, to reduce any ambiguity in such cases.

#### Note on the `version` key

*More on the rationale: [no-version-field-rule](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/no-version-field-rule.md)*

Avoid specifying the `version` key (e.g. `version: '3.8'`) among the top-level properties of a Compose YAML file, as it is a deprecated key in current versions of Compose; current versions of Compose automatically determine the version of a file, based on the features used. 

#### Miscellaneous
When it comes to ordering labels and environment variables within a service, there are no exact guidelines for this repository: the main priority, here, is for ease of reading, so using alphabetical order or visually separating lines into categorized groups, may be helpful in certain scenarios.

### Arguments (for the program being run as the entrypoint)
Many applications expect you to provide in arguments when running them in the command line (e.g. `my-program run ./file.txt --debug=TRUE`), as a way to dynamically provide data, control behavior, or configure any other options; in many cases, command line arguments are the only way to get a program to run in a specific way (as compared to environment variables and config files). The Compose specification allows you to specify just that, with the `command` attribute for a service; the values of `command` are appended to the entrypoint (whether in the `entrypoint` attribute of a service or the image's default entrypoint, defined in the `ENTRYPOINT` instruction of its Dockerfile), to create the full command that the container will run.

The `command` key can be specified as either a single string, or a sequence of strings. For example, here is a Compose configuration that treats the `command` key as a single string:
```yaml
services:
  database:
    ... # Omitting for brevity
    command: --default-authentication-plugin=mysql_native_password
    ...
```

This can work well in cases where the list of arguments is relatively short. However, you may want to specify a large amount of arguments for a container; in that case, you can treat the `command` key as an (ordered) sequence of strings, like in this Compose configuration:
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

This approach is highly flexible, allowing you to easily change the order of strings, insert YAML comments between arguments, and, importantly, it allows you to not worry about whitespace being interpreted incorrectly (e.g. when file names with spaces are being used); however, with whitespace, strings will not be stripped of whitespace automatically, so any unexpected whitespace (e.g. at the end of strings) may result in unexpected behavior. Furthermore, you are even able to use multi-line strings as individual arguments for the `command` key, like in this Compose configuration:
```yaml
services:
  velocity:
    ... # Omitting for brevity
    command:
      - /bin/sh
      - -c
      - |
        echo -n '${VELOCITY_FORWARDING_SECRET}' > '/config/forwarding.secret'
        exec /usr/bin/run-bungeecord.sh
```

The above configuration uses multi-line strings as a way to pass a full shell script to `/bin/sh` (which the entrypoint is assumed to run at the end of its own script); note that, for longer scripts, you may want to write them as a separate file that gets mounted to the container and is provided as an argument, as the operating system may not like highly long argument strings.

Note that `command` overrides the values in the `CMD` instruction of a Dockerfile, which are the default set of extra arguments to append to the arguments of the entrypoint. As well, note that `command` defines extra arguments to be specified for the program specified in the entrypoint; often, images are designed to run a script that performs other tasks before running the main program itself. Furthermore, many images use scripts that treat their arguments as a full command to run at the end, and they can even use `command`/`CMD` as the way to specify the main application's complete command.

For example, here is a service that uses both the `entrypoint` and `command` keys:
```yaml
services:
  example:
    ... # Omitting for brevity
    command:
      - "/app/entrypoint.sh"
      - "--type=PROD"
    entrypoint:
      - "/bin/my-program"
      - "run"
      - "--detached"
```

The `command` key is specified as a sequence of strings: `/app/entrypoint.sh` and `--type=PROD`. The `entrypoint` key is specified as a sequence of strings, as well: `/bin/my-program`, `run`, and `--detached`. When the container is created, its full command to run will be `/app/entrypoint.sh`, `--type=PROD`, `/bin/my-program`, `run`, and `--detached` (typically, when manually writing commands in a shell, arguments are separated by whitespace, and the shell automatically uses whitespace to separate the arguments into separate strings). For this example image, `/app/entrypoint.sh` is a script that takes any number of arguments (for the script itself) that start with `--`; any arguments after those will be interpreted as a complete command to execute at the end of the script, which would be `/bin/my-program.sh`, `run`, and `--detached`. In this scenario, modifying `command` will be modifying the complete command, including the path of the program being invoked, for the main application that would be run at the end of the script; treating `command` as just a sequence of arguments for the main application itself may result in unexpected behavior.

In any case, before modifying the `command` (and/or `entrypoint`) key of a service, be sure to review the Dockerfile of the image being used, so that there are no misunderstandings of what is being modified.

### Environment variables, fragments, and overall plumbing
Sometimes, for a Compose stack file, you may have values that you do not want in plaintext (e.g. secrets), but still need a way to provide those values to a certain container. In many cases, you may want to determine certain options and values only at deploy time (as opposed to being defined within the Compose stack file), to allow for flexibility between different deployment instances (e.g. multi-server stack setups). For these scenarios, environment variables (and interpolation with environment variables) are a way to accommodate these needs in a simple and secure manner. Here is an example of environment variables in action for a Compose stack file:
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

The use of environment variables allows for these values to not be defined (in plaintext) in the stack itself, but be provided by Docker Compose (and indirectly by Komodo). Note that, in the context of a Compose stack file, there is no functional difference between secret-specific environment variables and non-secret environment variables; the difference only matters for Komodo, which is what provides all of the environment variables to Docker Compose.

As an important note, for a Compose stack file, there are two contexts in which environment variables are used: environment variables provided directly to Docker Compose, when processing a Compose file, and environment variables provided directly to a container for a Compose service. Note that these sets of environment variables are distinct, as an environment variable provided to Docker Compose may not necessarily be provided to a container, but, often, environment variables provided to Docker Compose are what set the values of environment variables provided to containers. This can be confusing, but this does provide much power when creating Compose stack files. References to environment variables can be placed ANYWHERE in a Compose file, and Docker Compose will automatically, at deploy time, replace (interpolate) those references with the values of the environment variables it has been provided.

Typically, like in the previous example, we simply use environment variables provided to Docker Compose to define the environment variables that are provided to the containers, via interpolation.

It is also possible to use environment variables (provided to Docker Compose) to define non-environment variable attributes. For example, here is an environment variable (provided to Docker Compose) being used to define the value of a label of a service:
```yaml
services:
  netbootxyz:
    ... # Omitting for brevity
    labels:
      ...
      traefik.http.middlewares.netboot-auth.basicauth.users: "${NETBOOT_LOGIN}"
    ...
```

Furthermore, the use of environment variable interpolation is not limited to defining (entire) values of YAML attributes, but also parts of keys (and comments), like in this example:
```yaml
services:
  example:
    ... # Omitting for brevity
    labels:
      ...
      example.users.${USERNAME}.allow-login: "TRUE"
```

`${USERNAME}` will be replaced with the value of the environment variable, `USERNAME`, when Docker Compose processes the file.

As well, you are able to set default values for references to environment variables, so that, if an environment variable is unset or empty for Docker Compose, the reference will be replaced with the default value instead; the format for this is `${ENVIRONMENT_VARIABLE:-DEFAULT_VALUE}`. Here is an example of a Compose stack file that uses this:
```yaml
services:
  vert:
    ... # Omitting for brevity
    environment:
      ...
      PORT: "${PORT:-3000}"
      ...
```

In this file, if the environment variable, `PORT`, is not defined at deploy time, then the string, `${PORT:-3000}`, will be replaced with `3000` instead.

For more information on interpolation, please refer to the [specific section on interpolation in the official Compose specification](https://github.com/compose-spec/compose-spec/blob/main/12-interpolation.md).

Importantly, when using environment variables whose values may be interpreted as booleans, integers, or floats, to define attributes that may expect strings, you should use quotes around the environment variables to ensure that YAML interprets the value as a string, like in this Compose stack file example:
```yaml
services:
  example:
    ... # Omitting for brevity
    environment:
      TARGET_PORT: "${TARGET_PORT}"
```

When `${TARGET_PORT}` is interpolated (e.g. as `3000`), the quotes around it will ensure that it looks like `"3000"`, so that the YAML parser treats it as a string, which environment variables expect.

When using environment variables within a Compose stack file, it is generally good practice to have comments specifying all of the environment variables that need (or may need) to be set, as well as any instructions for (or important notes) on their values, within the first lines of the file, like this: 
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

As a further aside, it is also good practice to list these environment variables (and instructions) within the README.md for the Compose stack being defined in the same order as in the comments.

#### On .env files (vs regular environment variables)
The approach of using interpolation (of environment variables provided to Docker Compose) is not the only way to provide environment variables to a service; it is also possible to pass in files with environment variable definitions directly to containers. Typically, Komodo also writes the contents of environment variables that are provided to it to `.env`, in the working directory of a Stack resource. Here is an example of this in action, for a Compose stack file:
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

For the `homepage` service, Docker Compose will read the contents of `./.env` and pass all environment variables defined in the file (which are all the environment variables directly provided to Komodo) directly to the container behind the service. As well, it is possible to provide multiple environment variable files, beyond `.env`, like the environment variable file for secrets, defined in the `SOPS_SECRETS_PATH` environment variable, that can be created by SOPS and be passed to Docker Compose; this will be covered in more depth later in this section on environment variables.

Note that the main downside of this is that we are unable to selectively control (or modify) what environment variables are provided to a container that uses this `env_file` approach.

```yaml
services:
  ... # Omitting for brevity
  # This expects to be given a path to a secrets file (by the "docker compose up" command)
  # to use for secrets as environment variables
  homepage:
    ...
    env_file:
      - ./.env
...
```

#### Fragments (anchors)
There are many cases where defining certain values only at deploy time (with environment variables) may not be necessary, but you still may want to have flexibility in how they are defined. In other cases, you may need to use an identical value many times within a Compose stack file, yet want to have a single source of truth for it, to avoid the error-prone process of repeatedly changing the same value in different places. There are even cases where, maybe, you don't need to have a single source of truth, but still want to have an easy-to-find location to define values that may be frequently modified. In these scenarios, fragments are the way to accommodate such needs; with fragments, we get to define re-usable blocks (YAML values), using anchors, anywhere in a file, and then reuse them, with aliases, anywhere else within the file. This feature proves to be incredibly useful for reducing boilerplate and streamlining important value definitions. 

Note that anchor resolution only takes place *after* variable interpolation, so we cannot use environment variables to name anchors or aliases; on the other hand, this does mean that we can use variable interpolation for the values used in the fragments themselves, which we will cover later.

To define an fragment, specify its name in the format of `&FRAGMENT_NAME` (`&` is the anchor, and should have no spaces after it) after the naming of a key (and its colon), but before the definition of the value, like this:
```yaml
x-common:
  MY_KEY: &my-key "my-value"
```

Note that, typically for our repository, fragments are defined in special top-level properties, named x-properties, since the names of the properties always start with `x-`.

To use the fragment somewhere else in the file, reference the name of the fragment in the format of `*FRAGMENT_NAME` (`*` is the alias, and should have no spaces after it, too), right after the naming of a key, but before the naming of another key:
```yaml
services:
  example:
    ... # Omitting for brevity
    environment:
      VALUE_1: *my-key
      VALUE_2: "value-2"
      ...
```

Note that fragments can only be used to define entire YAML values for YAML keys, and can't be used anywhere else, such as in the middle of strings.

For more information on fragments, please refer to the [specific section on fragments in the official Compose specification](https://github.com/compose-spec/compose-spec/blob/main/10-fragments.md).

Beyond simple values (e.g. strings), fragments can also refer to entire dictionaries (and sequences), too; these dictionary fragments are also able to be imported into other dictionaries, by using them with an alias, for the `<<` attribute. Here is an example of this in action, in a Compose stack file:
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

In the above example, the value for the `database` key (in `x-common`) is named, with an anchor, as `db-environment`, which is reused later in the `environment` key of the `database` service. Note that that the values of sub-attributes of attributes that have anchors, can also be made into individual fragments, with more anchors; this is useful for defining entire blocks of configuration that may be used wholesale for one service while still picking out individual values to provide to other services. As well, alongside the importation of a dictionary fragment, more attributes can be individually defined for the dictionary that is importing the values.

Furthermore, it is also possible to import multiple dictionary fragments into another dictionary at once; this is done by defining the `<<` key as a sequence of aliased fragment names (the order is important, as later fragments may override the values of previous fragments), like in this example Compose stack file:
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

In the above example, we define multiple fragments that are dictionaries: `panel-environment`, `mail-environment`, and `backup-environment`. All of these get referenced, with a list of aliases, and imported into the `panel` service's `environment` property, which is a dictionary. All of the imported dictionaries' values, alongside the individually named attributes, get merged, in order, to make up the final dictionary that makes up the `environment` property.

As mentioned before, both variable interpolation and fragments can be used together, to allow environment variables to define the values of fragments, which will then get referenced and used in other places in the YAML file; this is useful for minimizing the repeated use of environment variables and keeping single sources of truth. Again, note that variable interpolation takes place *before* anchor resolution, and not the other way around, so be careful not to use variables to define the names of fragments. Here is an example of the two features being combined in a Compose stack file:
```yaml
x-common:
  ... # Omitting for brevity
  MAIL: &mail
    ...
    N8N_SMTP_PASS: "${MAIL_PASSWORD}"
    ...

services:
  ...
  n8n:
    environment:
      <<: *mail
      ...
```

In the above file, `${MAIL_PASSWORD}` will first be interpolated with the value of the `MAIL_PASSWORD` environment variable; the value of this will then be used to define the `N8N_SMTP_PASS` attribute of the `mail` fragment, which will be imported into the `environment` property of the `n8n` service. This allows for both the definition of reusable blocks and the ability to defer the value definition of certain properties to deploy time.

Finally, it is possible for the values of fragments to reference other fragments; the parser will resolve all required anchors until there are none left (this does mean that you should avoid circular dependencies). Here is an example that utilizes this:
```yaml
x-common:
  ... # Omitting for brevity
  POSTGRES: &postgres
    POSTGRES_USER: &postgres_user "postgres"
    POSTGRES_NON_ROOT_USER: &postgres_non_root_user "postgres_nonroot"
    POSTGRES_DB: &postgres_db "n8n"
  MAIL: &mail
    N8N_SMTP_SENDER: "n8n <homelab@saphnet.xyz>"
    ...

x-services: # Base instances of services to customize
  N8N_COMMON: &n8n_common
    ...
    environment:
      <<: [*mail]
      ...
      DB_POSTGRESDB_DATABASE: *postgres_db
      DB_POSTGRESDB_USER: *postgres_non_root_user
      ...
    ...
```

In the above example, there is an `x-common` top-level property, that defines various fragments that are used in the other sections, including the `x-services` top-level property. The `x-services` top-level property, which defines fragments to be used in the definition of multiple services, then references these fragments in its on defition; various services later on in the file will, in turn, import the values defined in `x-services`.

#### Secrets
There may exist certain values for your stack that are required for its functioning, but also cannot be stored in plaintext, whether in the Compose stack file, or in a Stack resource file for Komodo, due to their exposure potentially leading to misuse and unauthorized access; these types of values are called **secrets**, which encompass data such as passwords, API keys, and tokens. The main tool used for handling secrets in the Sapphic Homelab/Home Server is SOPS (short for Secrets OPerationS), which encrypts sensitive values in configuration files with public keys before writing them to a file; this allows us to store these secrets publicly (e.g. in a Git repository) without worrying about exposing them, as long as the private keys involved are kept secure. To decrypt these secrets before using them, SOPS is also used, being called by Komodo when calling Docker Compose to deploy a Compose stack; each server should have a unique private key that only it has access to, provided at server deploy time, to use with SOPS. Note that a Compose stack file can only see the values of secrets-related environment variables, and not where they come from, or how they were created; the direct use of SOPS is only within the scope of Stack resources in Komodo itself.

For our Compose stacks, there is a standard way to store SOPS secrets. All SOPS secrets are in the .env format, separated into files by Server-specific instances, named after the name of the Server resource being targeted for the instance, all ending in the extension `.enc.env` (to differentiate it from a normal `.env` file); all of these files (per stack) are then stored in the `secrets` subdirectory of the Compose stack directory (the directory holding the Compose YAML files). This is an example of what this would look like for a Compose stack:
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

There can be as little as only one SOPS secrets file (if the stack is only being deployed on one server with secrets); conversely, there is no upper bound to the number of SOPS secrets files that can be stored.

Before creating SOPS secrets, we do need to make sure that the `.sops.yaml` file (in the repository's root directory) is properly configured for the target server(s). The `.sops.yaml` file is a special file that defines what keys are available to SOPS, and for what kinds of file paths, like this:
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

The top-level properties in this file are `keys` and `creation_rules`. `keys` is a sequence of public keys (as strings) that SOPS can use; note that each public key has an anchor next to it, with a name (typically for the Server that it is for), which creates a fragment that can be reused multiple times throughout the file. `creation_rules` is a sequence of dictionaries that represent rules for assigning groups of keys to different paths (represented with a regex expression under the `path_regex` property of the rule); each rule then has the `key_groups` property, which is a sequence of dictionaries representing groups of keys. Each property for each group of keys represents the type of key (e.g. age, pgp, etc.) for which its sequences of keys are; for example, we have the `age` property for the first group, which is a sequence of age public keys, which are referenced through aliases.

To edit a SOPS secret file, use the command `sops edit SECRETS_FILE_NAME`; note that the environment with which you are running SOPS must have a private key corresponding to one of the public keys used in the relevant creation rule for your secrets file (e.g. `admin`, for the main admin keypair). As well, the `sops edit` command can also be used to create SOPS secrets files that do not exist yet.

The main way of using SOPS secrets is through variable interpolation: the Stack configuration is set to have SOPS pass the secrets to environment variable of Docker Compose, and then Docker Compose will replace references to those variables with the values that it is given. Here is an example of a Compose stack file configured to take advantage of this:
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

Note that this allows us to use these secrets anywhere in the Compose stack file, and not just in environment variables passed to the service container.

When writing SOPS secrets files with the interpolation approach in mind, secrets must be written in a strict `KEY=VALUE` format, like this:
```ini
EXAMPLE_VARIABLE=foobar
EXAMPLE_VARIABLE_2=abcd$1234$=
```

This format of SOPS secrets file has no spaces before or after the `=` symbol, and strings are treated very literally, with no `$` symbols being escaped with a backslash, and no quotes, as they will be included in the value of the environment variables.

The other way of using SOPS secrets is by having SOPS create a `.env` file from the decrypted contents of the secrets file, and then pass the path of the file to Docker Compose as an environment variable; the file, after variable interpolation, gets listed in the `env_files` property of the service(s), and then the contents of the entire file are used in the creation of the environment of the service container. Here is an example of a Compose stack file using this approach:
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

The convention in our repository is that the environment variable with the path of the decrypted SOPS secrets file is named as `SOPS_SECRETS_PATH`, and that the variable references in Compose stack files using this approach are configured to fail if the environment variable is unset at deploy time.

Furthermore, the way SOPS secrets files are written for this approach are slightly different: it still uses the strict `KEY=VALUE` format, but the file is parsed, like in a shell script, when Docker Compose processes it before passing its contents to the environment of the container. This means that quotes are stripped from values, and that environment variable references will be interpolated in the evaluation of these values, unless the values are wrapped in single quotes (`'`'). Here is an example of a SOPS secrets file written with this in mind:
```sh
EXAMPLE_VARIABLE='foobar'
EXAMPLE_VARIABLE_2='abcd$1234$='
```

Note that the values of each environment variable are wrapped in single quotes, so that the contents within the quotes are interpreted literally (no interpolation is done); if there were no single quotes, or if double quotes (`"`) were used instead, `$` symbols would have to be escaped with backslashes, so that `$1234` wouldn't be interpreted as an environment variable to be interpolated.

This approach allows for only the secrets file to be concerned with the specific keys of the environment variables (as opposed to the Compose stack file, too), reducing any error-prone repetition when there exists a large number of environment variables that may change frequently. The downsides of this approach, however, are that the contents of the secrets file are passed wholesale to containers (we are unable to be selective anymore), and that it will be harder to use the values of the secrets in the interpolation process of a Compose stack file.

### Networking
Often, a container is not useful on its own, at least without the ability to connect to other containers or be connected to from outside the host; for this, Compose provides the ability to connect services to (internal) networks as well as expose ports on services to outside the host.

Before planning any networking-related changes to your Compose stack file, make sure that your service's container name is the same as the name of the service itself (the key that defines the Compose service):
```yaml
services:
  foldingathome:
    image: ... # Omitting for brevity
    container_name: foldingathome
    ...
```

This is the convention for Compose stack files on the Sapphic Homelab/Home Server, and more importantly, this allows for other containers to be able to easily connect to the container with a consistent name, even when the stack changes names or the service moves between stacks; without setting the `container_name` property, Docker containers created for Compose services are automatically named in the format of `STACKNAME_SERVICENAME`.

To expose a port on a service's container to outside the host (to bind the container's port to a port on the host), simply add an entry for the port mapping to the service's `ports` property (a sequence of strings):
```yaml
services:
  ... # Omitting for brevity
  deluge-sftp:
    ...
    ports:
      - "2222:22"
    ...
```

For each port mapping, the number on the left represents the port to connect to on the host, while the number on the right represents the port on the container to bind the host's port to, in the format of `"HOST_PORT:CONTAINER_PORT"`. Note that all entries in the `ports` property are wrapped in quotes; this is because all port mappings are represented as strings, and using quotes forces a YAML parser to treat the value is a string (as opposed to a number). You are able to map as many ports on the host to ports on the container as you like, provided that nothing else on the host is using the port(s); this flexibility means that, in the case of many containers expecting to use the same port, each container still can be given a unique port to avoid conflicts.

For inter-container connectivity, Compose uses Docker networks; each Docker network is a unique object (with a unique name) representing an internal network through which containers on the network can connect with each other. To define a network and connect a container to it, create an entry in the `networks` top-level property with the desired name of the network, and then add the name of the network to the `networks` property (a sequence) of the desired service(s). Here is an example of this in action, for a Compose stack file:
```yaml
services:
  foldingathome:
    image: ... # Omitting for brevity
    container_name: foldingathome
    ...
    networks:
      - example_network

networks:
  example_network:
```

Note that, for a network to be defined (in the context of a Compose stack), only the name of the network has to be specified in `networks`; all other options for the network entry (a dictionary) are optional.

However, you may want to connect to a Docker network that is defined outside of the Compose stack (e.g. `web_bridge` for Traefik). To do so, under the definition of the network, specify the (globally accessible) name of the Docker network under the `name` property and define the `external` property as `true` (to tell Docker Compose that the network is externally managed, and doesn't need to be created):
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

Generally, the network name to use when connecting with the Traefik instance of a host (to use its reverse proxy features) is `web_bridge`; this will be covered in more depth in the Traefik section.

Importantly, note that, from the perspective of the Compose service, the `web_bridge` network is simply a Compose-defined network, like any other, but the configuration of `web_bridge` defines it as a specific Docker network. Furthermore, note that the `web_bridge` network entry still has to specify the name of the Docker network, even though the network (within Compose) already has a name; this is because Compose-defined networks and Docker networks are different in scope. All Compose-defined networks are mapped to Docker networks at deploy time, but it is Docker Compose that manages them; by default, the name of a Docker network for a Compose stack's network is in the format of `STACKNAME_NETWORKNAME` (where, again, `NETWORKNAME` stands for the Compose network's name). We specify `name` to tell Docker Compose that the Compose network maps directly to a specific Docker network, and not something else that is internally defined by Docker Compose. For this reason, when creating networks in Compose stacks to be connected to by services in other stacks, the `name` property should still be specified, to avoid surprises and mismatches.

Again, multiple services within a Compose stack can be connected to the same Compose network; not only that, Compose services can be connected to multiple Compose networks, like in this Compose stack file:
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

Note that, when there are no extra networks defined, Docker Compose automatically creates a special network for all services in the Compose stack. When there are networks defined in the stack, this network may not automatically be created, so, like in the above example, we generally create another special Compose network to be used within the stack to connect all (relevant) services to, for inter-connectivity.

In certain cases, we may want a service's container to use the network space of the host itself, rather than have specific ports on the container be bound to ports on the host. For example, we may want to use firewall rules on the host's port (e.g. to limit where connections can come from); however, Docker may override rules that may be set on the firewall, since it also directly manages the kernel's routing rules. Using the host's network space, in such a scenario, allows us to bypass Docker's routing features, and allow the firewall to work as expected. Here is an example of this in action, for a Compose stack file:
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

Note that this means that the container has complete access to any port on the host, and that we are unable to (as easily) map application ports to different host ports; to solve this, you may want to set a special environment variable or argument for your application to use a different port. As well, this approach prevents the container from being able to use Docker/Compose networks, and so inter-container connectivity may have to be done through ports exposed on the host itself.

Still, we are still able to specify what interface on the host to bind a container's port to, to limit what interfaces can connect to the container through that port; this is done by specifying the IP address of the interface, before the ports being mapped, in the specific entry in the `ports` property, like in this Compose stack file: 
```yaml
services: # To be connected to by Homepage
  docker-proxy:
    ... # Omitting for brevity
    ports:
      - "${HOST_IP:-0.0.0.0}:2375:2375"
    ...
```

In this specific example, environment variables (for Docker Compose) are used to specify the IP address of the interface to bind to, as it may be hard to know what the IP address before deploy time, or as the IP address may be dynamic; in such cases, like in the example, there is also a default value used (if the environment variable is unset) of `0.0.0.0`, which simply means that all interfaces on the host can connect to the port. The convention for this repository is that the name of the environment variable is `HOST_IP`.

#### On VPN containers
In certain cases, you may not want a service's container to connect to the Internet through the host's IP address (and routes), but rather, through that of another location/host. In such cases, you can use a VPN container to connect that container to. A VPN container is a special container that handles connections to/from the VPN, communicating with the kernel to set up the necessary routes (this means that you will need to provide it with certain capabilities). In general, you will want to use the [Gluetun client](https://github.com/passteque/gluetun) for VPN purposes, as it is a lightweight client, designed for Docker, that supports a plethora of VPN services and technologies.

Here is an example of a VPN container, using Gluetun, for a Compose stack service: 
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

In the entry for the service connecting through the VPN, the `network_mode` property is set as `service:vpn`; this means that it uses the network space of another service in the stack, which is `vpn` in this case. Furthermore, there is an entry in the `depends_on` property, which is a dictionary with the name of the service for the VPN connection (`vpn`), whose `condition` property is `service_healthy`; this means that Docker Compose will wait for the `vpn` service to report itself as healthy (fully working) before starting the `deluge` service.

As well, you may notice that all configuration for port mappings, networks, and Traefik labels are specified under the `vpn` service and not the `deluge` service; this is because the `deluge` service uses the network space of the `vpn` service, meaning that any connections to/from applications within the `vpn` service have to be done through the `vpn` service. If other network-related settings are specified under the `deluge` service, it will result in an error at deploy time.

Note that `cap_add`, `devices`, and `sysctl` properties specified in the `vpn` service: the `NET_ADMIN` entry in the `cap_add` property allows the container to manage network interfaces and routes, the `/dev/net/tun:/dev/net/tun` entry in the `devices` property gives the container the virtual network device to use for managing virtual tunnels, and the `sysctls` property allows for more fine control over network settings, like disabling IPv6 for this connection. All of these properties are necessary for ensuring that the VPN container has what it needs for managing VPN connections.

The environment variables provided to Gluetun are highly specific to the VPN server and its type of connection; for more information, please refer to [the official Gluetun wiki](https://github.com/qdm12/gluetun-wiki).

### Volumes, mounting
Docker containers are ephemeral, meaning that any data written within any of their directories that aren't backed up by external sources will be deleted when the container is taken down; containers are meant to be destroyed and recreated, like in the case of updates. You may have data created through the containers that you may want to keep (be persistent) between this cycle of destruction and creation, such as databases, records, and media.

In this scenario, Docker volumes are used to solve this problem; volumes provide a safe place, decoupled from the container, to store data in, and are managed by Docker (and Docker Compose). Volumes get mounted to specific locations in a container when the container is created, so that all data accessed in that location is done through the volume. Typically, volumes are on local storage (on the host itself), but they can also be on other kinds of storage, like network shares; this will be covered in more depth in the next sections. As well, multiple containers can use the same volume at once, and have the volume mounted in different locations (between containers).

To define a volume in a Compose stack file, you only need to specify its name as a key in the `volumes` top-level property; all options for a volume are optional. Here is an example of a volume being defined in a Compose stack file:
```yaml
volumes:
  guac-db-data:
```

To mount this volume to a specific location in a service's container, the volume's name, and the target directory, need to be specified as a mapping in an entry in the `volumes` key of a service (which is a sequence of strings), in the format of `VOLUME_NAME:/PATH/TO/DIRECTORY`, like in this Compose stack file:
```yaml
services:
  guacdb:
    ... # Omitting for brevity
    volumes:
      - guac-db-data:/var/lib/mysql
    ...
```

Note that the convention is to not use quotes around the entry of a volume mapping.

In addition to Docker volumes, directories (and files) on the host can also be mapped to locations on the container, in this format: `/LOCATION/ON/HOST:/LOCATION/ON/CONTAINER`. Here is an example of this in action, for a Compose stack file.
```yaml
services:
  guacdb:
    ... # Omitting for brevity
    volumes:
      - /directory/on/host:/var/lib/mysql
    ...
```

Note that this approach is not as portable as using Docker volumes, as it is reliant on the directory structure of the host, which may differ between hosts. However, this approach may be the only option in cases where Docker volumes are unable to be used for a certain purpose.

As well, like networks, which have different scopes between that of a Compose stack and within Docker's global context, volumes are also different between within a Compose stack file and in Docker itself. All Compose-defined volumes are mapped to Docker volumes at deploy time, but it is Docker Compose that manages them; by default, the name of a Docker network for a Compose stack's network is in the format of `STACKNAME_VOLUMENAME` (where, again, `VOLUMENAME` stands for the Compose volume's name). If you want to make sure a volume's name stays the same, between stacks, specify `name` to tell Docker Compose that the Compose volume maps directly to a specific Docker volume, and not something else that is internally defined by Docker Compose; doing this is not as necessary for volumes as for networks, but this fact may be important to consider for specific cases.

#### Mounting non-Compose config files
- Docker Compose only takes in compose files, and while you can do a lot with them, you may still need to provide other configuration files, so volumes feature can be used here, mount files on repo to specific location in container
- remember that containers don't have access to files unless given, and it has to be mounted in specific places (which can be to our advantage, since we can organize our stacks directory how we want, and we can map it to how program expects it)
- stuff about making sure relative to root of stack directory
- note about read-only, to avoid potential issues, since it is IaC

One thing that mounting files from the host to a container is useful for is non-Compose config files that are tracked in the Git repository, in the same directory (or within a subdirectory of) the Compose stack's directory. Docker Compose can only (directly) be given Compose YAML files, and while the Compose YAML schema provides many features, there may be cases where you will need to provide another file from the repository to the container, such as scripts or other long configuration files. In such cases, file mounting is the only way to provide the file(s) to the container, as containers do not have access to files on the system, unless explicitly given. As well, file mounting provides us with the flexibility to structure the config files within a Compose stack's directory however we see fit, as each file can be mapped from anywhere on the host (our repository, in this case) to anywhere in the container's directory structure; the application(s) within the container may expect specific config files to be in specific locations, but this file mounting approach allows us to decouple that from how the directory in the repository is organized.

This is an example Compose stack directory structure, to demonstrate how such non-Compose config files can be organized:
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

Again, note how flexible the organization of config files can be. They can sit directly under the Compose stack directory, alongside the Compose YAML file(s), or be categorized together and placed in subdirectories. This allows for maximum readability and ease of navigation.

To mount a config file from the Compose stack's directory, simply write an entry under the service's `volumes` top-level property, in the format of `./PATH/TO/FILE/ON/REPO:/PATH/EXPECTED/IN/CONTAINER:ro`. Here is an example of this being used in a Compose stack file:
```yaml
services:
  velocity:
    ... # Omitting for brevity
    volumes:
      - ./velocity-config/velocity.toml:/config/velocity.toml:ro
```

Note that the path on the host's side is relative (and not absolute), as the absolute path on the host may differ between deployments, but the current working directory should always be that of the directory of the Compose stack (this is configured on Komodo's side, through the Stack resource). As well, we append `:ro` at the end, as this marks this mount as read-only; since the Sapphic Homelab/Home Server uses the GitOps approach for Compose stacks, it should be the contents of the Git repository that dictate the state of an application, and not the other way around (as in the application changing the configuration), as the changes will be lost in a redeployment, so setting the mount as read-only enforces this approach.

#### NAS storage mounts
For certain persistent storage needs, you may not want to use a normal Docker volume. Normal Docker volumes, without any further configuration, are stored locally, on the host, in the directory that Docker is configured to store volumes in. However, the host may simply not have enough storage for your needs, you may want to take advantage of the capacity and features of a NAS, the data you want to use may already be on a NAS, you may want the data to outlast a Stack (or even a Server), or, for some other reason, you just don't want the data to be stored on the host at all. In such scenarios, you can make use of the NFS volume driver to create a Docker volume that's actually backed by a NAS; all data in this volume will have to be read from and written to the NAS.

When creating a volume to be backed by a NAS, you will need to have a specific location on the NAS to store its data, and an NFS share through which the Komodo host can access its contents. For example, in TrueNAS, you may need to create a dataset on a specific datapool, intended for use with NFS, and then create a NFS share that exposes the location (and contents) of that dataset to other clients; note that it is best practice to limit the IP addresses/hostnames that can access the NFS share to those of the Komodo hosts running the relevant Compose stacks.

An NFS-backed Compose volume is mostly treated the same as a normal Compose volume, but with special configuration options under the entry for that volume, under the `volumes` top-level property, like in this Compose stack file:
```yaml
volumes:
  ... # Omitting for brevity
  netboot-assets: # Bootable assets (e.g. live CDs)
    driver_opts:
      type: "nfs"
      o: "addr=nas1.int-net.saphnet.xyz,nolock,soft,rw,nfsvers=4"
      device: ":/mnt/saphnet-nas1c/netboot-assets"
```

All relevant options are under the `driver_opts` property of the volume's entry, to configure the volume to use the NFS driver. The `type` property is specified as `nfs`, as the volume uses NFS. The `o` property (a string) represents all the options (relevant to NFS mounts), separated by commas, that are passed to the `mount` command (when mounting the NFS share to the volume's directory on the host) with the `-o` argument, like in `mount -t nfs -o OPTIONS DEVICE TARGET`. Under `o`, we specify `addr` as the hostname of the NAS (`nas1.int-net.saphnet.xyz` in this case), `nolock` to disable file locking (to improve compatibility with the NFS server), `soft` to report errors to the program in case of NAS unreachability (instead of forcing the program to wait with `hard`), `rw` to enable both reads and writes, and `nfsvers=4` to set the NFS version to be version 4 (a more recent version of NFS, which we recommend). Generally, for most volumes using NFS shares, these options will suffice. The `device` property lists the the location of the NFS share on the NAS, in the format of `:/PATH/TO/SHARE/LOCATION` (note the `:` symbol in the beginning); for TrueNAS hosts, the format may be something similar to `/mnt/DATAPOOL/DATASET[/SUBDATASET...][/SUBDIR...]` (e.g. `/mnt/saphnet-nas1c/netboot-assets`).

*For more information on the options that can be specified within the `o` property, refer to [this guide on the `mount` options for NFS file systems](https://docs.oracle.com/cd/E19253-01/816-4555/rfsrefer-16/index.html).*

Mounting an NFS-backed volume to a service is the same as mounting any other volume to a service, where you add an entry to the `volumes` property of the service, as a string in the format of `VOLUME_NAME:/PATH/TO/DIRECTORY`. Here is an example of the volume in the previous example being mounted to a location in a service's container:
```yaml
services:
  netbootxyz:
    ... # Omitting for brevity
    volumes:
      ...
      - netboot-assets:/assets
      ...
```

As well, you can create as many volumes as desired that reference the same locations of the NFS shares (as well as their subdirectories), for the purpose of having different directory structures within different containers.

Note that, if the NAS with the NFS share is down while a container is running, the container may stall (lock up) when attempting to access a file on the NFS share until the NFS server is running again, even with the `soft` option provided; try to keep this in mind when managing the NAS with the relevant share.

### Device mounting (e.g. GPUs)
Certain services in certain Compose stacks may require access to hardware devices for certain functionality, such as GPUs for accelerating transcodes. Providing access to these devices is as simple as listing their corresponding device files (for Linux) or their parent directories under the `devices` property of the service.

For example, for non-NVIDIA GPUs, it is as simple as providing access to `/dev/dri` (the directory containing the device files for GPUs) to the service, like in this Compose stack file:
```yaml
services:
  vertd:
    ... # Omitting for brevity
    devices:
      - /dev/dri
    ...
```

For NVIDIA GPUs, however, it is more complicated. You will need to set the `runtime` property of the service as `nvidia`, and then set specific options under the `deploy` property of the service to provide access to the NVIDIA device, like in this Compose stack file:
```yaml
services:
  vertd:
    image: ... # Omitting for brevity
    container_name: vertd
    ...
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [ gpu ]
    ...
```

### Traefik

*More on how to configure Traefik*: [Traefik README](stacks/traefik/README.md)

In terms of website functionality (through HTTPS), the main way to have a Compose service be accessible to the outside world is to configure the service so that that Traefik can discover it and automatically provide an endpoint to access the service with; Traefik is the main reverse proxy used in the Sapphic Homelab/Home Server, and about all Komodo hosts should have an instance of it running. Here is an example of a Compose stack file with the bare essential options to create an secure endpoint for a service with Traefik:
```yaml
services:
  jellyfin:
    image: ... # Truncating here
    networks:
      - web_bridge # Traefik, in this instance, connects to services via the web_bridge network, so we need to be reachable through it
      ...
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

networks:
  web_bridge:
    name: web_bridge
    external: true
```

First, note that there is a network, `web_bridge`, defined under the `networks` top-level property, using the specific Docker network, `web_bridge` (specified in the `name` property), marked as externally managed (through `external`); for any Komodo service, the network that Traefik uses is named `web_bridge` (in both its Compose stack and in Docker itself), and any service that is serviced by Traefik needs to connect to this network in order for Traefik to connect to it. As well, the `web_bridge` is listed as one of the network(s) under the `networks` property of the `jellyfin` service.

Next, the main way Traefik works, within the context of a Komodo host, is through Docker labels; Traefik constantly scans new containers, looking for specific labels under the `traefik` label namespace. If it detects containers with labels that are marking them to be used with Traefik, it will use the values of those labels as its configuration to be used for those containers.

Here are some labels of importance:
- `traefik.enable`: If this is set to `true` for a container, Traefik will know that it is a container that it can service.
- `traefik.http.routers.ROUTER_NAME`: These labels configure a specific router (each router has a unique name), the endpoint through which Traefik will listen to external traffic. Note that routers are generally named after the Compose services they service, for our repository.
  - `traefik.http.routers.ROUTER_NAME.rule`: This sets the specific endpoints and conditions for which the router is configured. In this example, it is set to `` Host(`jellyfin.media.int.saphnet.xyz`) ``, which means that it will only listen to traffic directed to the host, `jellyfin.media.int.spahnet.xyz`.
  - `traefik.http.routers.ROUTER_NAME.entrypoints`: This sets the entrypoint (the specific port(s) and what type of protocols they serve) for the router. For our repository, we generally set the entrypoint to `websecure`, which is defined on our Traefik instances to be HTTPS, on port 443.
  - `traefik.http.routers.ROUTER_NAME.tls`: This determines whether TLS is enabled for this router, which it is (`true`); this generally should be `true` for routers using `websecure`.
  - `traefik.http.routers.ROUTER_NAME.tls.certresolver`: This determines what certificate resolver is used for generating TLS certificates. Generally, for Compose stacks in this repository, it should be `letsencrypt` (like in this example), as it is already configured in our Traefik instances to use the Let's Encrypt service for generating such certificates.
  - `traefik.http.routers.ROUTER_NAME.service`: This determines the Traefik service to direct traffic from the router to, as routers are only for managing endpoints. In this case, it is defined as the `jellyfin-svc` service, which is defined in the next label.
- `traefik.http.services.SERVICE_NAME.loadBalancer.server.port`: This defines a Traefik service, which is a resource that defines to what backend servers traffic is directed to (in this case, a service with the name `jellyfin-svc`), and then provides it with the configuration for a server for the service's load balancer; in this case, the load balancer's server is just defined with the port on the specific container to direct traffic to (`8096`).
  - Note that, for our repository, Traefik services are generally named after the routers they are connected to, but with `-svc` appended as a suffix.

This section only scratches the surface of how a Compose stack service can be configured to be serviced by Traefik. For more information on how to configure Traefik for a Compose service, please read [the README of the Compose stacks for Traefik](stacks/traefik/README.md).

### Other custom functionality (entrypoints, scripts, init services)
For various Compose stacks, before (or during) the deployment of a service, specific tasks may need to be done first, such as creating files and databases, for the main service to be able to function completely (and as expected); often, these tasks cannot be done with the default functionality or execution flow of the application(s) run in the service's container. In such scenarios, custom entrypoints, custom scripts, and special init containers can be used for performing these tasks. 

Custom entrypoints are generally simple to set up; simply configure the `entrypoint` property of the service as a sequence of strings representing the program to run as well as its arguments, like in this Compose stack file:
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

The above example configures the entrypoint as a call to the Bash shell, with the main argument representing the list of commands to run under Bash, in the `bash -c COMMANDS` format; note that this means that we can have the entrypoint run a multi-line script, as while the entrypoint can only represent one command, this command can represent a payload being given to a shell that can run that payload. The multi-line script first downloads a file to a specific location in the container, and then runs the main entrypoint script provided by the image, to return to normal execution.

Using a custom entrypoint allows you to do anything within the context of the service's container, including modifying its internal directory structure. However, please note that there are many caveats and considerations that exist with this approach.

Firstly, the way the arguments are written, and separated, for the `entrypoint` property matter a lot. Each string, after being parsed by the YAML parser, will be processed literally (with no further parsing or whitespace stripping, like in a shell) and be treated as a complete argument (with no further splitting); if specific arguments are split (into separate YAML strings) incorrectly, or if there are any unexpected characters in any argument (e.g. extra whitespace at the end of a string), the called program may fail to work as expected. If you are unsure about how to split strings for a command, consider how you would write the command into a shell: if a space (or multiple) separates tokens (sequences of non-space characters, in this case), then those tokens should be considered as separate strings in the YAML sequence, and if any sequence of characters (spaces included) are wrapped in quotes to treat it as a single argument, then that sequence of characters should be treated as an unbroken string in the YAML sequence for `entrypoint`. Note that, like in the above example, individual arguments can span multiple lines, which can be represented with YAML multi-line strings; this is highly useful for passing multi-line scripts to `/bin/bash`.

Importantly, the Docker image's default `ENTRYPOINT` values may be performing tasks (such is running specific scripts) that are highly important for the container's functioning. Before modifying the `entrypoint` property of your Compose service, be sure to consult the Dockerfile of the relevant image to understand what is being called, and if there are any scripts being imported into the Dockerfile and used for `ENTRYPOINT`, to understand their purpose. In many cases, you may just want your entrypoint to be a short script that performs special tasks before passing control to the regular entrypoint script in the image, which should allow you to only focus on stack-specific needs, while leaving the rest to what was already defined in the image; 

As well, setting the `entrypoint` does not necessarily make values of `CMD` (the extra arguments attached to the end of a Docker image's `ENTRYPOINT`) empty. If the Docker image's default values for `CMD` are not empty, then they may be appended to the end of the `ENTRYPOINT` values (to form the full command to run the container with) and lead to unexpected behavior. In any case, make sure to read the Dockerfile of the relevant image to determine the necessary course of action, and whether the values of `CMD` provide anything that may need to be moved to another part of the Compose service's definition.

Again, in any case, before modifying the `entrypoint` (and/or `command`) key of a service, be sure to review the Dockerfile of the image being used, so that there are no misunderstandings of what is being modified. In addition, the contents of the Dockerfile may be subject to change, including the contents of the `ENTRYPOINT` and `CMD` values, as well as of the scripts being referred to in the image, so be sure to check an image's Dockerfile before updating the image, in order to be able to prepare for potential changes.

If the intended contents of the script span more than a few lines (or are otherwise long), it may be more desirable to write it as a separate script file that gets mounted to the container, with the entrypoint command being pointed to its location on the container; this allows us to avoid any potential limits on the length of a single command, and separate the concerns of the Compose stack file from that of the script. Here is an example of this in action, for a Compose stack file:
```yaml
services:
  example:
    ... # Omitting for brevity
    volumes:
      - ./custom-entrypoint.sh:/custom-entrypoint.sh:ro
    entrypoint:
      - /custom-entrypoint.sh
```

Here is what `custom-entrypoint.sh` would look like, for this example:
```bash
#!/bin/bash

# This is an example of a command being run in the entrypoint
mkdir /app/data
# The rest of the file is just a Bash script
```

In the above example, the `custom-entrypoint.sh`, presumed to be in the root of the Compose stack directory, is mounted to `/custom-entrypoint.sh` on the container, so that it is accessible on the container. Note that `:ro` is appended to the end of the `volumes` entry; this is to prevent the script from being modified by containers (to only be modified through GitOps). Furthermore, any script file intended to be executed by a container should always be marked as executable; this can be done by running `chmod +x FILE_NAME`. Under the `entrypoint` property, the only entry is `/custom-entrypoint.sh`; this will instruct the container to directly run that script as an executable. Note that, when using the file directly, instead of passing it to a shell like `/bin/bash`, that the first line of the script should be in the format of `#!/PATH/TO/SHELL`, to instruct the operating system as to what shell executable to run the script with (e.g. `#!/bin/bash`).

Certain images may already have functionality to run other scripts that exist in directories, allowing us to hook extra functionality without modifying the entrypoint; this depends on the speciifc Docker image, so please consult its Dockerfile or documentation for more information (e.g. the locations of the special directories). Here is an example of a Compose stack file that uses this functionality for a service with such an image:
```yaml
services:
  postgres:
    ... # Omitting for brevity
    volumes:
      ...
      - ./init-data.sh:/docker-entrypoint-initdb.d/init-data.sh
    ...
```

Here is what `init-data.sh` looks like for the above example:
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

In the above example, the entrypoint script (of the image of the `postgres` service) runs any scripts in the `/docker-entrypoint-initdb.d` directory before starting the main application (PostgreSQL). The `init-data.sh` script does initial configuration for the Postgres database (to ensure that it is ready to use by other services); this script file is mounted into the `/docker-entrypoint-initdb.d` directory, so that the entrypoint automatically runs it. Note that neither the default execution flow nor the entrypoint have to be modified for the contents of `init-data.sh` to be run.

This approach may be preferable to modifying the `entrypoint` property of a service, assuming the Docker image supports such an approach.

> TODO rewrite (once Docker Compose is at version >=5.3.0 for all Komodo hosts) to use the approach described in https://docs.docker.com/compose/how-tos/init-containers

Another approach to running custom tasks before/during the deployment of a service is to create a service for an init container: an init container is a special container, with its own image and tools, that is configured to perform specific tasks, and then exit, before another container can run. There is more plumbing involved, in terms of configuring the Compose stack and service, but it does mean that the contents of the container (or its entrypoint) do not need to be modified beforehand, which can lead to a cleaner (and more modular) setup. As well, using a separate image for the init container means that we can pick any image that suits our needs, with any amount of tools included.

Note that init containers do not have access to the internal directory structure of the container that it complements, so they can only be used to configure anything external to the container (e.g. volumes and external databases); for anything specific to the container itself, you will need to use custom entrypoints and custom scripts mounted directly to the container, instead.

Here is an example of a Compose stack file that uses an init container service to complement another service:
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
    # NOTE: AVOID setting the restart property as "unless-stopped", as the
    #       init container service should NOT be continuously running!

volumes:
  example-service-data:
```

In the above example, `init-helper` is defined as another Compose service; it uses the `alpine` package, as it is a lightweight image that works well for general-purpose needs, with most base Linux tools built in. As it is designed to work with a volume that the `example-service` service will use (`example-service-data`), the volume is mounted to somewhere within the `init-helper`; the location of such a mount is flexible, as long as the script that the container runs knows where it is, and as long as the mount doesn't conflict with pre-existing Linux directories (e.g. directly to `/etc`).

Note that, unlike other types of services/containers, the init container service should NOT have its `restart` property to be configured as `unless-stopped`, as they are intended to run only once (not continuously).

More importantly, the `init-helper` service has an entrypoint configured, that consists of a multi-line script being fed into the `/bin/bash` executable (of the image). For init containers, the `entrypoint` property is where its main purpose is defined; in this example, the entrypoint is for a Bash script that generates a file for a secret for the `example-service-data` volume, if it does not exist yet.

Again, note that if the intended contents of the entrypoint script span more than a few lines (or are otherwise long), then it should be made into a separate script file and mounted to the init container, in the same process shown earlier in this section.

For an init container service to work as an init container service, the Compose service(s) that need it to run first must be configured to wait for the init container service to successfully exit (with the exit code 0). This is done by listing the name of the Compose service for the init container as a dictionary key under the `depends-on` property of the dependent Compose service(s); under the dictionary entry for the init container service, under `depends-on`, the `condition` property must be set to `service_completed_completely`, to configure the dependent service(s) to start only after the init container has exited (as opposed to starting once the init container has started).

As another note, when creating Stack resources for Komodo (which will be covered in further depth later in this guide), with Compose stacks that contain init container services, remember to configure the Stack to ignore the state of the init container service when determining the status of the Stack, as exited init containers may cause Komodo to incorrectly conclude that the Stack is unhealthy, when the init container has only done its job.

### Writing stacks to be run across multiple servers
A Compose stack is only a blueprint; turning a Compose stack (deploying a stack) into actively running containers requires Docker Compose to be run, with the stack's files, potentially with environment variables provided to Docker Compose when deploying; this stage of running and configuring Docker Compose is what Komodo focuses on when managing Stack resources. Like a regular blueprint, you could theoretically build (deploy) it as many times as you would like; in certain cases, using the same Compose stack file(s), as-is, across multiple servers may work sufficiently for the needs of the stack.

However, you may want to distinguish each instance of the Compose stack, between servers, in some manner (e.g. unique identification), or provide each instance with different data and arguments for their specific needs. In some cases, using environment variables to define simple YAML values in Compose stack files that distinguish the instances of those Compose stacks may suffice, if those are the only types of values that differ between instances. Here is an example of a Compose stack file where this approach will work:
```yaml
services:
  simple-service:
    ... # Omitting for brevity
    environment:
      SERVER_ID: "${SERVER_ID}"
    ...
```

In the above example, the `simple-service` service requires the `SERVER_ID` environment variable (for the container) to be set, as this is what provides the applicaion within the container a way to identify itself. Since an environment variable is just a string, we can use another environment variable (from the scope of Docker Compose) to define its value, which is, again, `SERVER_ID`; since each instance of a Compose stack has to be defined by a Stack resource, which are specific to a Server (for Komodo), each Stack resource using the Compose stack files can have their own value for the `SERVER_ID` environment variable, allowing for instances to be easily distinguished without the use of extra Compose YAML files.

On the other hand, certain Compose stack resources cannot be distinguished easily through simple YAML value swaps; there may be pieces of functionality that may only exist for one instance but not another, or different instances may require different structures for their data, like with labels. In that case, you will need to create extra Compose YAML files for each instance. Generally, a multi-instance Compose stack with this approach is split into a main Compose YAML file with configuration shared by all instances (e.g. image names) that all instances will use/reference, and then individual Compose YAML files for each instance (each named after the Komodo Server that they run on) with individualized configuration options for an instance's needs. For any instance of a Compose stack using this approach, the contents of the main YAML file and the instance-specific YAML file will be merged, by Docker Compose, when deploying the instance of the Compose stack.

*For more information on Compose YAML file merging, refer to [the section of the official Compose specification on merging](https://github.com/compose-spec/compose-spec/blob/main/13-merge.md).*

One way to handle this approach is to split the Compose YAML files into a base file (entirely designed to be only run alongside an instance file) and multiple instance files, where both types of file are provided to Docker Compose at deploy time; Docker Compose will recursively combine the values of the provided files, with precedence being determined by the order of the files provided (later files will be prioritized when there are conflicts).

This is what the directory structure of a Compose stack using this approach would look like:
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

As shown in the example, the name of the base file should generally be `base.yaml`, to distinguish it from `compose.yaml`, as `compose.yaml` (for this repository) indicates a Compose stack file that can be run standalone. Furthermore, the name of the instance-specific files should be named after that of the Server (a Komodo resource) that they are intended to be deployed on, so a file intended for use with the `control-server` Server should be named as `control-server.yaml`. As well, any secrets files (under the `secrets` subdirectory) for instances should be also named after the name of the intended Server, so a secrets file for the `control-server` Server would be named `control-server.enc.env`, and placed under `secrets`.

This is what a `base.yaml` file for a multi-instance Compose stack would look like:
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

Notice that this file has almost everything needed to run an instance of the `docker-volume-rclone` stack, such as image names, some basic environment variables, and an NFS-backed volume. However, also notice that there are some missing values that need to be filled before the Compose stack can successfully be deployed: the `TARGET_SUBDIR_NAME` and `VOLUME_NAMES` environment variables. For this approach, the instance-specific files are what provide the missing values, and these values are what get combined with the configuration of the base file. This is an example of what an instance-specific file looks like (for control-server, in this case):
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

Notice that the `environment` property of the corresponding service includes values for the necessary missing environment variables.

When combined, the final Compose YAML file for the Compose stack should look like this:
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

Again, when creating a Stack resource (for Komodo) that targets a Compose stack using this approach, make sure to include filenames for both the base YAML file and the instance-specific files in the `file_paths` property. As well, the order of the listing of the filenames matters is crucial; Docker Compose, when provided with multiple Compose YAML files, will recursively merge dictionary values, so that all unique keys under a certain property across the files will all be combined together in the final file, but when there are keys whose values are not dictionaries or sequences (e.g. strings), values defined in files listed later take override the values of earlier files for the same key. For sequences, when a key defined across multiple files as a sequence, the sequences will be appended to each other in order of file order, so the values of a (sequence type) key in a later file are listed after the values of that same key defined in an earlier file; the exceptions to this are for shell command properties of services, like `command`, `entrypoint`, and `healthcheck.test`, where definitions of the same key in later files override those of earlier files. For special circumstances, you can also use the `!reset` and `!override` YAML tags, in later YAML files, to reset and override the previous definitions of specific properties; these tags would be placed between the specification of the key (and the `:` symbol) and the specification of the value.

The other way to handle this approach (for multi-instance Compose stacks) is to split the Compose YAML files into a base file that can run standalone (but still has all the values that all instances share) and multiple instance files that extend that base file (with the `extends` property for a service), where only one or the other types of file is provided to Docker Compose (not both); the values of the instance-specific file get overlaid on top of that of the base file, if used.

This is what the directory structure of a Compose stack using this alternative approach would look like:
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

Like in the example, the name of the base file should generally be `compose.yaml`, as opposed to `base.yaml`, to indicate it that can be run standalone. Furthermore, like the previous approach, the name of the instance-specific files should be named after that of the Server (a Komodo resource) that they are intended to be deployed on, and any secrets files for instances should be also named after the name of the intended Server, under the `secrets` subdirectory of the Compose stack directory.

This is what a `compose.yaml` file for a multi-instance Compose stack (with this approach) would look like:
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

Notice that this file has virtually everything needed to run an instance of the `glances` stack, besides Traefik labels, which are completely optional. 

This is an example of what an instance-specific file looks like, for this approach (for docker-host-core, in this case):
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

Notice that the comment mentions not to provide both the `compose.yaml` file and the instance-specific file to Docker Compose, as the instance-specific file already comes with a reference to `compose.yaml`. Furthermore, `glances` is defined as a service that is based off of the `glances` service in `compose.yaml`; the resulting service will be a combination of that referenced service's configuration and the extra configuration provided in `labels`, with conflicting values from the instance-specific file overriding those of `compose.yaml`. Note that this approach is more granular than the previous approach; you only pick specific services to extend and won't inherit any more of the configuration of the referenced file. This is an example of what Docker Compose might resolve the final YAML to be:
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

Importantly, as stated before, note that the approach of using the `extends` property is much more granular than in the previous approach where all top-level properties of all provided files are merged and considered in the final Compose YAML file. This means that any volumes, networks, etc. that the extended service (the service being referred to by the instance-specific file) refers to and depends on will not also be imported (and be useable) in the final Compose YAML file; to use those resources, they will have to be individually re-defined in the instance-specific file, with `extends` defined for each one. In such a scenario, this may lead to a lot of unwanted, error-prone repetition, potentially across many files. If you still want to use this approach of still having a standalone base `compose.yaml` file without those problems, you are also able to use the previous approach that does not rely on `extends`, but ensure that the base file is named as `compose.yaml` and can run on its own.

### Writing a README
**TLDR**: For a README for a Compose stack, write for someone who may not know anything about the stack but still wants to instantiate it for a specific server (with a Komodo Stack resource)! You are welcome to assume that they understand Docker and other related technologies, but give them enough instruction to be able to create something from scratch with the stack.

A README for a Compose stack generally starts with the name of the Compose stack, and the name should be decorated as Header 2 (using `##`). After the name should be a quick one-line description of what the stack is for and what it does; this will be the same description that will be used in Komodo Stacks that use the Compose stack. Generally, descriptions for stack aren't complete sentences, but rather a complete noun phrase (and other modifiers), capitalized like a sentence, and with a period at the end. Here is an example of what this looks like for the `vertd` stack:
```markdown
## vertd
The daemon that handles video conversions for the VERT.sh service, with GPU acceleration.
```

After the description, if there are any environment variables, you should specify all of the environment variables that need (or may need) to be set, as well as any instructions for (or important notes) on their values. These should be in the same order as in the comments on environment variables in the Compose stack file; you are able to copy the descriptions from those comments, too. This is an example of what it looks like for the `velocity-vps` stack:
```markdown
When deploying, make sure to set these environment variables with your secrets:
- `VELOCITY_FORWARDING_SECRET` - The forwarding secret to use with Velocity, for the purposes of authentication
- `RCON_PASSWORD` - The password to login into Velocity's RCON server with (**IMPORTANT**: avoid using `#` in your password!)
- `SFTP_PASSWORD` - The password to login into the SFTP server as `velocity-user` with
- `TAILSCALE_IP` - For the SFTP and RCON servers, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)
```

As well, if the Compose stack requires any more work to configure outside of any GitOps-tracked files within the stack directory, such as within the Komodo Stack configuration or in terms of manual work (e.g. account creation via a web portal), you should include instructions for (or important notes on) getting the stack and applications ready for use. This can be in the form of a step-by-step guide on how to navigate a web portal workflow, a set of commands to run in one part of the process, or a note on custom options you may want to set for your needs. In addition, if there are any important pieces of info that relate to what is required on the Komodo host, or the overall management of the stack, you should also list them as things to note.

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

### Ignoring init containers
- 

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