## gickup
A solution for backing up Git repositories.

When deploying, make sure to set these environment variables with your secrets:
- `TIMEZONE` - The name of a [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to use as the timezone (you can use the `TIMEZONE` Variable from Komodo)
- `GITHUB_TOKEN` - The token to use to log into GitHub, preferably classic. Make sure that this has permission to read private repositories (e.g. the `repo` scope). (To generate a token, go to https://github.com/settings/tokens)
- `S3_ENDPOINT` - The URL endpoint to use to connect to the S3-compatible server
- `S3_REGION` - The region to use for the S3-compatible server (e.g. `garage`)
- `S3_ACCESS_KEY_ID` - The ID for the access key for the S3-compatible server
- `S3_SECRET_ACCESS_KEY` - The access key itself for the S3-compatible server

Note that this stack requires access to an S3-compatible server for storage.