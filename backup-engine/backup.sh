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

DATE=$(date +%F-%H%M)
MONTH=$(date +%Y-%m)
BACKUP_DIR="/backup/backup_$DATE"
BACKUP_TAR="/backup/backup_$DATE.tar.gz"
EMAIL_SUBJECT_SUCCESS="MongoDB Backup Success - $DATE"
EMAIL_SUBJECT_FAIL="MongoDB Backup FAILED - $DATE"
EMAIL_BODY="/backup/email_body.txt"

# Create a temporary email body file
echo "Backup Log for $DATE" > $EMAIL_BODY
echo "--------------------------" >> $EMAIL_BODY

# Run mongodump
if mongodump --host $MONGO_HOST --port $MONGO_PORT \
  --username $MONGO_USER --password $MONGO_PASS \
  --authenticationDatabase $MONGO_AUTH_DB \
  --out=$BACKUP_DIR >> /backup/backup.log 2>&1; then
    
    tar -czf $BACKUP_TAR -C /backup "backup_$DATE" >> /backup/backup.log 2>&1
    rm -rf $BACKUP_DIR

    echo "Status: MongoDump Successful." >> $EMAIL_BODY
    echo "File: $BACKUP_TAR" >> $EMAIL_BODY
    
    # Upload to Google Drive
    if [ -f /root/.config/rclone/rclone.conf ]; then
        # Capture error only if it fails
        # Uploading to monthly folder: e.g. /mongo-backups/2026-02/
        RCLONE_LOG=$(rclone copy $BACKUP_TAR $RCLONE_DRIVE:/mongo-backups/$MONTH/ --config /root/.config/rclone/rclone.conf 2>&1)
        RCLONE_STATUS=$?
        if [ $RCLONE_STATUS -eq 0 ]; then
            echo "Cloud Sync: Success (Google Drive -> /mongo-backups/$MONTH/)" >> $EMAIL_BODY
        else
            echo "Cloud Sync: FAILED" >> $EMAIL_BODY
            echo "Error Detail: $RCLONE_LOG" >> $EMAIL_BODY
        fi
    else
        echo "Cloud Sync: SKIPPED (rclone.conf missing)" >> $EMAIL_BODY
    fi
    
    # Send success email
    sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "$EMAIL_SUBJECT_SUCCESS" \
      -m "$(cat $EMAIL_BODY)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS" -o tls=yes -o message-charset=utf-8 >> /backup/backup.log 2>&1
else
    echo "Status: MongoDump FAILED" >> $EMAIL_BODY
    echo "Check /backup/backup.log inside container for details." >> $EMAIL_BODY
    sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "$EMAIL_SUBJECT_FAIL" \
      -m "$(cat $EMAIL_BODY)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS" -o tls=yes -o message-charset=utf-8 >> /backup/backup.log 2>&1
fi

# Cleanup local backups older than 7 days
find /backup -type f -name "*.tar.gz" -mtime +7 -delete >> /backup/backup.log 2>&1
