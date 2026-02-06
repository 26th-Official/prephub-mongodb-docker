#!/bin/bash

# Set environment variables with fallbacks FIRST
EMAIL_TO="${EMAIL_TO:-you@example.com}"
SMTP_SERVER="${SMTP_SERVER:-smtp.example.com}"
SMTP_USER="${SMTP_USER:-your-smtp-user}"
SMTP_PASS="${SMTP_PASS:-your-smtp-password}"
MONGO_HOST="${MONGO_HOST:-mongodb}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-root}"
MONGO_PASS="${MONGO_PASS:-example}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"
RCLONE_DRIVE="${RCLONE_DRIVE:-docker}"

# This script is called by cron for scheduled backups
# Test email is handled separately by startup.sh

DATE=$(date +%F-%H%M)
BACKUP_DIR="/backup/backup_$DATE"
BACKUP_TAR="/backup/backup_$DATE.tar.gz"
EMAIL_SUBJECT_SUCCESS="MongoDB Backup Success - $DATE"
EMAIL_SUBJECT_FAIL="MongoDB Backup FAILED - $DATE"
EMAIL_BODY="/backup/email_body.txt"

# Create a temporary email body file
echo "" > $EMAIL_BODY

# Run mongodump into directory with per-collection BSONs
if mongodump --host $MONGO_HOST --port $MONGO_PORT \
  --username $MONGO_USER --password $MONGO_PASS \
  --authenticationDatabase $MONGO_AUTH_DB \
  --out=$BACKUP_DIR; then
    
    # Optional: tar+gzip the whole backup directory into one file
    tar -czf $BACKUP_TAR -C /backup "backup_$DATE"

    # Remove the original directory after archiving
    rm -rf $BACKUP_DIR

    echo "MongoDB backup successful: $BACKUP_TAR" > $EMAIL_BODY
    
    # Upload to Google Drive
    if [ -f /root/.config/rclone/rclone.conf ]; then
        rclone copy $BACKUP_TAR $RCLONE_DRIVE:/mongo-backups/ --config /root/.config/rclone/rclone.conf --progress
    else
        echo "Warning: rclone.conf not found. Skipping cloud upload." >> $EMAIL_BODY
    fi
    
    # Send success email
    sendemail -f $SMTP_USER -t $EMAIL_TO -u "$EMAIL_SUBJECT_SUCCESS" \
      -m "$(cat $EMAIL_BODY)" -s $SMTP_SERVER -xu $SMTP_USER -xp $SMTP_PASS -o tls=yes
else
    echo "MongoDB backup FAILED at $(date)" > $EMAIL_BODY
    sendemail -f $SMTP_USER -t $EMAIL_TO -u "$EMAIL_SUBJECT_FAIL" \
      -m "$(cat $EMAIL_BODY)" -s $SMTP_SERVER -xu $SMTP_USER -xp $SMTP_PASS -o tls=yes
fi

# Optional: remove local backups older than 7 days
find /backup -type f -name "*.tar.gz" -mtime +7 -delete
