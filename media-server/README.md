## Media server
A media server designed to integrate with the Deluge Seedbox, using Jellyfin, Jellyseerr, Prowlarr (suported with Flaresolverr), Radarr & Sonarr (supported with Recyclarr), and Bazarr. Note that there are two groups of Radarr/Sonarr-related containers, for anime and non-anime media.

NOTE: Relies on Traefik setup.

For ideal results, make sure your virtual machine has access to a GPU with good transcoding support.

This setup is designed to work with an NFS server, with a central directory for a media server, with the following subdirectories:
- `jellyfin`: Has the subdirectories `config` and `cache`, for Jellyfin to directly interact with, as well as these subdirectories:
  - `movies`: A directory that contains non-anime movie files, from Radarr (non-anime).
  - `tv`: A directory that contains non-anime TV show files, from Sonarr (non-anime).
  - `anime-movies`: A directory that contains anime movie files, from Radarr (anime).
  - `anime`: A directory that contains anime TV show files, from Sonarr (anime).
- `deluge`: Has the subdirectories `torrent_files` and `torrent_downloads`, respectively for .torrent files and completed downloads, which the Deluge Seedbox deals with.

When deploying, make sure to set these environment variables with your secrets:
- `TAILSCALE_IP` - For certain services with exposed ports that bypass Traefik, set this if you want to restrict the interfaces from which it can be reached (e.g. restricting from public access)