## netboot.xyz
A host for providing network access to different operating systems via PXE and HTTP.

NOTE: For other hosts to know to access the TFTP server provided by Netboot, be sure to follow the instructions in this link to advertise this server: [DHCP Configurations](https://netboot.xyz/docs/docker/dhcp)

This setup relies on an NFS share to store everything in `/assets`, as all the data would be too much to store locally.