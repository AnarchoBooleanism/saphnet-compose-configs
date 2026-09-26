## docker-volume-rclone
A solution for regularly cloning Docker volumes to a remote NFS location.

Should be customized for each system, with each system's volumes specified in the `VOLUME_NAMES` environment variable. Make sure to update these configs when changing anything related to volumes.

To set up an instance for a host, use this template:
```yaml
services:
  docker-volume-rclone:
    environment:
      TARGET_SUBDIR_NAME: SETME_HOSTNAME
      VOLUME_NAMES: >-
        EXAMPLE_VOLUME_1
        EXAMPLE_VOLUME_2
```

To run this, use a host-specific file and `compose.base.yaml` together, so that structure of `compose.base.yaml`, with the default configuration settings, is merged with your instance-specific structure; an example would be with `docker compose -f compose.base.yaml -f compose.control-server.yaml up`

When deploying in Komodo, make sure to set these environmental variables with your secrets:
- `TARGET_SUBDIR_NAME` - The (unique) hostname of the host running the service
- `VOLUME_NAMES` - Space-delimited list of Docker volumes on the host to back up
- `TIMEZONE` - The name of a [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to use as the timezone (you can use the `TIMEZONE` Variable from Komodo)

For more details, make sure to refer to [the documentation of the image repo](https://github.com/AnarchoBooleanism/docker-volume-rclone).