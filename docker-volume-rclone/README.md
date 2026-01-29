## docker-volume-rclone
A solution for regularly cloning Docker volumes to a remote NFS location.

Should be customized for each system, with each system's volumes specified in the `VOLUME_NAMES` environment variable. Make sure to update these configs when changing anything related to volumes.

To set up an instance for a host, use this template:
```yaml
include:
  - ./base.yaml

services:
  docker-volume-rclone:
    <<: *docker-volume-rclone
    environment:
      <<: *environment
      TARGET_SUBDIR_NAME: SETME_HOSTNAME
      VOLUME_NAMES: >-
        EXAMPLE_VOLUME_1
        EXAMPLE_VOLUME_2
```

In this setup, `base.yaml`, which includes extensions and fragments with default values to create the `docker-volume-rclone` service with, as well as the NFS volume being mounted. The main environment variables to set here are `TARGET_SUBDIR_NAME`, which is the (unique) hostname of the host running the service, and `VOLUME_NAMES`, which is a space-delimited list of Docker volumes on the host to back up.

For more details, make sure to refer to [the documentation of the image repo](https://github.com/AnarchoBooleanism/docker-volume-rclone).