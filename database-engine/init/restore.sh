#!/bin/bash
set -e

echo "Starting Database Restore Process (Database Engine)..."

# Find the backup file
BACKUP_FILE=$(ls /backups/*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$BACKUP_FILE" ]; then
    echo "Found backup file: $BACKUP_FILE"
    echo "Extracting backup..."
    mkdir -p /tmp/dump
    tar -xzf "$BACKUP_FILE" -C /tmp/dump
    
    # Use environment variables set in docker-compose or Dockerfile
    if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
        echo "Authenticating as root..."
        mongorestore --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin /tmp/dump
    else
        echo "No root credentials found, attempting restore without authentication..."
        mongorestore /tmp/dump
    fi
    
    echo "Cleaning up extraction folder..."
    rm -rf /tmp/dump
else
    echo "No .tar.gz backup file found in /backups/ directory."
fi

echo "Restore Process Completed! 🚀"
