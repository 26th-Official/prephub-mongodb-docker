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
  --out=$BACKUP_DIR; then
    
    tar -czf $BACKUP_TAR -C /backup "backup_$DATE"
    rm -rf $BACKUP_DIR

    echo "Status: MongoDump Successful." >> $EMAIL_BODY
    echo "File: $BACKUP_TAR" >> $EMAIL_BODY
    
    # Upload to Google Drive
    echo "" >> $EMAIL_BODY
    echo "Rclone Upload Log:" >> $EMAIL_BODY
    if [ -f /root/.config/rclone/rclone.conf ]; then
        # Capture BOTH stdout and stderr to the email body
        rclone copy $BACKUP_TAR $RCLONE_DRIVE:/mongo-backups/ --config /root/.config/rclone/rclone.conf -v 2>&1 >> $EMAIL_BODY
        RCLONE_STATUS=$?
        if [ $RCLONE_STATUS -eq 0 ]; then
            echo "Rclone: Upload finished successfully." >> $EMAIL_BODY
        else
            echo "Rclone: Upload FAILED with exit code $RCLONE_STATUS." >> $EMAIL_BODY
        fi
    else
        echo "Rclone: CRITICAL - /root/.config/rclone/rclone.conf NOT FOUND inside container." >> $EMAIL_BODY
    fi
    
    # Send success email
    sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "$EMAIL_SUBJECT_SUCCESS" \
      -m "$(cat $EMAIL_BODY)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS" -o tls=yes -o message-charset=utf-8
else
    echo "Status: MongoDump FAILED at $(date)" >> $EMAIL_BODY
    sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "$EMAIL_SUBJECT_FAIL" \
      -m "$(cat $EMAIL_BODY)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS" -o tls=yes -o message-charset=utf-8
fi

# Cleanup local backups older than 7 days
find /backup -type f -name "*.tar.gz" -mtime +7 -delete
