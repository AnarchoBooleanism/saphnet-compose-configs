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

To run this, use this file and `base.yaml` together, so that `base.yaml`'s structure, with the default configuration settings, is merged with your instance-specific structure; an example would be with `docker compose -f base.yaml -f control-server.yaml up`

The main environment variables to set here are `TARGET_SUBDIR_NAME`, which is the (unique) hostname of the host running the service, and `VOLUME_NAMES`, which is a space-delimited list of Docker volumes on the host to back up.

For more details, make sure to refer to [the documentation of the image repo](https://github.com/AnarchoBooleanism/docker-volume-rclone).