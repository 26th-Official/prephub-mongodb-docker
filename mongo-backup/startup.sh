#!/bin/bash

echo "Starting MongoDB backup container..."

# Send test email on startup
echo "Sending test email to verify email configuration..."
/backup/send_test_email.sh

if [ $? -eq 0 ]; then
    echo "Test email sent successfully!"
else
    echo "Warning: Test email failed to send. Check your email configuration."
fi

# Start cron daemon in foreground
echo "Starting cron daemon for scheduled backups..."
exec cron -f
