#!/bin/bash
set -e

echo "Starting Database Restore Process (Database Engine)..."

# Find the backup file
BACKUP_FILE=$(ls /backups/*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$BACKUP_FILE" ]; then
    echo "Found backup file: $BACKUP_FILE"
    echo "Extracting backup..."
    mkdir -p /tmp/restore_data
    tar -xzf "$BACKUP_FILE" -C /tmp/restore_data
    
    # --- Deep Directory Detection ---
    # We look for folders that contain .bson files
    # This handles backups wrapped in timestamp folders like backup_2026-02-06-0200/
    RESTORE_PATH="/tmp/restore_data"
    
    # Check if there's exactly one subdirectory and it's not a database name
    # Or simply find the first directory that contains a sub-directory with BSON files.
    DETECTED_FOLDER=$(find /tmp/restore_data -mindepth 1 -maxdepth 2 -type d \( -name "admin" -o -name "prephub" -o -name "test" \) -exec dirname {} \; | head -n 1)

    if [ -n "$DETECTED_FOLDER" ]; then
        RESTORE_PATH="$DETECTED_FOLDER"
        echo "Detected data folder: $RESTORE_PATH"
    fi

    # Use environment variables set in docker-compose
    if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
        echo "Authenticating as root and restoring from $RESTORE_PATH..."
        mongorestore --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin "$RESTORE_PATH"
    else
        echo "No root credentials found, restoring from $RESTORE_PATH..."
        mongorestore "$RESTORE_PATH"
    fi
    
    echo "Cleaning up extraction folder..."
    rm -rf /tmp/restore_data
else
    echo "No .tar.gz backup file found. Skipping restore."
fi

echo "Restore Process Completed! 🚀"
