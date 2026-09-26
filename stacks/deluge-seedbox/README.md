## Deluge Seedbox
A torrent client for file sharing, behind a VPN, and an SFTP server for accessing these files.

When deploying in Komodo, make sure to set these environmental variables with your secrets:
- `TOKEN` - NordVPN token for account login
- `CONNECT` - Name of NordVPN server to connect to
- `SFTP_PASSWORD` - Password to use for authentication of the SFTP server
- `TIMEZONE` - The name of a [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to use as the timezone (you can use the `TIMEZONE` Variable from Komodo)

Make sure, in the `seedbox-files` NFS volume, that there are directories for in-progress downloads, completed downloads, and .torrent files, which should be reflected in the Deluge settings.

Within the `deluge-config` volume, the `auth` file should be modified with the right login info, using the instructions from [this link](https://deluge-torrent.org/userguide/authentication/).

Within the `sftp-config` volume, the `sftp.json` file should be modified with the right login information.