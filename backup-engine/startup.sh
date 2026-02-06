#!/bin/bash

echo "Starting Backup Engine container..."

# Create environment file for cron jobs
echo "Creating environment file for cron..."
cat > /backup/cron_env.sh << EOF
export EMAIL_TO="$EMAIL_TO"
export SMTP_SERVER="$SMTP_SERVER"
export SMTP_USER="$SMTP_USER"
export SMTP_PASS="$SMTP_PASS"
export MONGO_HOST="$MONGO_HOST"
export MONGO_PORT="$MONGO_PORT"
export MONGO_USER="$MONGO_USER"
export MONGO_PASS="$MONGO_PASS"
export MONGO_AUTH_DB="$MONGO_AUTH_DB"
EOF

# Send test email on startup
echo "Sending test email to verify email configuration..."
/usr/local/bin/send_test_email.sh

if [ $? -eq 0 ]; then
    echo "Test email sent successfully!"
else
    echo "Warning: Test email failed to send. Check your email configuration."
fi

# Start cron daemon in foreground
echo "Starting cron daemon for scheduled backups..."
exec cron -f
