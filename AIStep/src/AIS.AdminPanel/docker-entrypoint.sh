#!/bin/bash
set -e

# Ensure /app/data directory has correct ownership for APP_UID
if [ -d "/app/data" ]; then
    echo "Fixing ownership of /app/data..."
    chown -R 1000:1000 /app/data
    chmod 755 /app/data
    echo "Permissions fixed"
fi

# Run the application
exec dotnet AIS.AdminPanel.dll "$@"
