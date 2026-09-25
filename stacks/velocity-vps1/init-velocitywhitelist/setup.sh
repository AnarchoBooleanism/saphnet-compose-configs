#!/bin/sh
# This script makes the assumption that only this script handles VelocityWhitelist
set -e

# VELOCITYWHITELIST_VERSION should be in SemVer format, with a leading "v", e.g. "v0.4.0"
VELOCITY_DATA_PATH=${VELOCITY_DATA_PATH:-'/velocity-data'}

# Common variables you might want to change
download_filename='VelocityWhitelist-${normalized_new_version}.jar'
download_url='https://github.com/TISUnion/VelocityWhitelist/releases/download/${VELOCITYWHITELIST_VERSION}/VelocityWhitelist-${normalized_new_version}.jar'
version_regex='s/v([0-9]+\.[0-9]+\.[0-9]+.*)/\1/p'
filename_regex='s/VelocityWhitelist-([0-9]+\.[0-9]+\.[0-9]+.*)\.jar/\1/p'

if [ -z "$VELOCITYWHITELIST_VERSION" ]; then
    printf "Environment variable VELOCITYWHITELIST_VERSION is empty!\n" >&2
    exit 1
fi

# Not sure how unstable versions will be labeled
if [ -z "$(echo "$VELOCITYWHITELIST_VERSION" | sed -nE "$version_regex")" ]; then
    printf '"%s" is not a valid VelocityWhitelist version!\n' "$VELOCITYWHITELIST_VERSION" >&2
    exit 1
fi

printf 'The latest VelocityWhitelist version is set to "%s".\n' "$VELOCITYWHITELIST_VERSION"

plugins_path="${VELOCITY_DATA_PATH}/plugins"

printf "Now checking whether the local VelocityWhitelist plugin file is up to date...\n"

if [ ! -d "$plugins_path" ]; then
    printf 'Directory "%s" does not exist! Creating...\n' "$plugins_path"
    mkdir -p "$plugins_path" || exit 1
fi

printf 'Searching directory %s...\n' "$plugins_path"

# Since the file names do not use "v"
export normalized_new_version=${VELOCITYWHITELIST_VERSION#?}

plugin_file_found="false"
plugin_versions_match="false"
current_plugin_path=$(find "$plugins_path" -maxdepth 1 -name "VelocityWhitelist-*.jar" -print -quit)
current_plugin_filename=$(basename "$current_plugin_path")

if [ -z "$current_plugin_path" ]; then
    printf "No VelocityWhitelist plugin file was found...\n"
else
    printf 'Found plugin file "%s"!\n' "$current_plugin_filename"
    plugin_file_found="true"
fi

if [ "$plugin_file_found" = "true" ]; then
    printf "Now checking whether the plugin file is up to date...\n"
    plugin_file_version=$(echo "$current_plugin_filename" | sed -nE "$filename_regex")
    echo "$current_plugin_filename"
    
    if [ -z "$plugin_file_version" ]; then
        printf 'Could not determine a version for the local plugin file...\n'
    elif [ "$plugin_file_version" = "$normalized_new_version" ]; then
        printf 'The version of the local plugin file, "v%s", matches the specified latest version, "v%s".\n' \
            "$plugin_file_version" "$normalized_new_version" 
        plugin_versions_match="true"
    else
        printf 'The version of the local plugin file, "v%s", does NOT match the specified latest version, "v%s"!\n' \
            "$plugin_file_version" "$normalized_new_version" 
    fi
fi

if [ "$plugin_file_found" = "true" ] && [ "$plugin_versions_match" = "true" ]; then
    printf "VelocityWhitelist is already up to date, now exiting...\n"
    exit 0
fi

local_download_directory=$(mktemp -d)
final_download_path="${local_download_directory}/$(echo "${download_filename}" | envsubst)"
final_download_url="$(echo "${download_url}" | envsubst)"

printf 'Downloading the plugin file for VelocityWhitelist version "%s"...\n' "$VELOCITYWHITELIST_VERSION"
printf 'Download URL is "%s"\n' "$final_download_url"
printf 'Destination path is "%s"\n' "$final_download_path"
curl -fL -o "${final_download_path}" "$final_download_url"

if [ "$plugin_file_found" = "true" ]; then
    printf 'Now, deleting any existing plugin file(s) in directory "%s"...\n' "$plugins_path"
    rm -v "$plugins_path"/VelocityWhitelist-*.jar
fi

printf 'Now moving the new plugin file for VelocityWhitelist version "%s" to directory "%s"...\n' \
    "$VELOCITYWHITELIST_VERSION" "$plugins_path"
mv -v "${local_download_directory}/VelocityWhitelist-${normalized_new_version}.jar" "$plugins_path"

printf "Finished updating VelocityWhitelist!\n"