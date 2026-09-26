## Folding@home
A program donating computing resources to science by simulating protein folding.

There is a `foldingathome` volume that you do need to keep in mind.

For ideal results, make sure your virtual machine has access to a GPU (preferably NVIDIA).

When deploying in Komodo, make sure to set these environmental variables with your secrets:
- `ACCOUNT_TOKEN` - Folding@home login token
- `TIMEZONE` - The name of a [tz time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to use as the timezone (you can use the `TIMEZONE` Variable from Komodo)