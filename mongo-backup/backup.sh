#!/bin/bash

TEST_EMAIL_FLAG="/backup/test_email_sent"

# Send test email if not already sent
if [ ! -f "$TEST_EMAIL_FLAG" ]; then
    echo "This is a test email from your MongoDB backup system." > /backup/email_body.txt
    sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "MongoDB Backup Email Test" \
      -m "$(cat /backup/email_body.txt)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS"
    
    # Create flag file so this runs only once
    touch "$TEST_EMAIL_FLAG"
fi

DATE=$(date +%F-%H%M)
BACKUP_FILE="/backup/backup_$DATE.gz"
EMAIL_TO="${EMAIL_TO:-you@example.com}"
EMAIL_SUBJECT_SUCCESS="MongoDB Backup Success - $DATE"
EMAIL_SUBJECT_FAIL="MongoDB Backup FAILED - $DATE"
EMAIL_BODY="/backup/email_body.txt"
SMTP_SERVER="${SMTP_SERVER:-smtp.example.com}"
SMTP_USER="${SMTP_USER:-your-smtp-user}"
SMTP_PASS="${SMTP_PASS:-your-smtp-password}"
MONGO_HOST="${MONGO_HOST:-mongodb}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-root}"
MONGO_PASS="${MONGO_PASS:-example}"
MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}"

# Create a temporary email body file
echo "" > $EMAIL_BODY

# Run mongodump
if mongodump --host $MONGO_HOST --port $MONGO_PORT --username $MONGO_USER --password $MONGO_PASS --authenticationDatabase $MONGO_AUTH_DB --archive=$BACKUP_FILE --gzip; then
    echo "MongoDB backup successful: $BACKUP_FILE" > $EMAIL_BODY
    # Upload to Google Drive
    rclone copy $BACKUP_FILE gdrive:/mongo-backups/ --progress
    # Send success email
    sendemail -f $SMTP_USER -t $EMAIL_TO -u "$EMAIL_SUBJECT_SUCCESS" -m "$(cat $EMAIL_BODY)" -s $SMTP_SERVER -xu $SMTP_USER -xp $SMTP_PASS
else
    echo "MongoDB backup FAILED at $(date)" > $EMAIL_BODY
    sendemail -f $SMTP_USER -t $EMAIL_TO -u "$EMAIL_SUBJECT_FAIL" -m "$(cat $EMAIL_BODY)" -s $SMTP_SERVER -xu $SMTP_USER -xp $SMTP_PASS
fi

# Optional: remove local backups older than 7 days
find /backup -type f -name "*.gz" -mtime +7 -delete
