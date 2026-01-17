#!/bin/sh
set -eu

trap "exit" TERM

# Create /app/config/sftp.json (login details, directory information)
cat > /app/config/sftp.json <<EOF
{
    "Global": {
        "Chroot": {
            "Directory": "%h",
            "StartPath": "sftp"
        },
        "Directories": ["sftp"]
    },
    "Users": [
        {
            "Username": "${SFTP_USERNAME}",
            "Password": "${SFTP_PASSWORD}"
        }
    ]
}
EOF

# Entrypoint from original image
exec tini -- dotnet ES.SFTP.dll