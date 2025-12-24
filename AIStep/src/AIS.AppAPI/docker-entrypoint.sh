#!/bin/bash
set -e

# Ensure /app/data directory has correct ownership for APP_UID
if [ -d "/app/data" ]; then
    echo "Fixing ownership of /app/data..."
    chown -R $APP_UID:$APP_UID /app/data
    chmod 755 /app/data
    echo "Permissions fixed"
fi

# Switch to APP_UID user and run the application
exec gosu $APP_UID dotnet AIS.AppAPI.dll "$@"
