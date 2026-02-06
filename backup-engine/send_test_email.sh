#!/bin/bash

EMAIL_TO="${EMAIL_TO:-you@example.com}"
SMTP_SERVER="${SMTP_SERVER:-smtp.example.com}"
SMTP_USER="${SMTP_USER:-your-smtp-user}"
SMTP_PASS="${SMTP_PASS:-your-smtp-password}"

# Ensure backup folder exists
mkdir -p /backup

# Write test email body to a file
EMAIL_BODY="/backup/test_email_body.txt"
echo "This is a test email from your MongoDB backup system." > "$EMAIL_BODY"

echo "Sending test email to: $EMAIL_TO"
echo "Using SMTP server: $SMTP_SERVER"

# Send the test email
sendemail -f "$SMTP_USER" -t "$EMAIL_TO" -u "MongoDB Backup Email Test" \
  -m "$(cat $EMAIL_BODY)" -s "$SMTP_SERVER" -xu "$SMTP_USER" -xp "$SMTP_PASS" -o tls=yes -o message-charset=utf-8
