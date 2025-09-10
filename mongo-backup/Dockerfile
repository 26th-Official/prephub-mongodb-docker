FROM mongo:latest

# Install cron, rclone, sendemail, and dependencies
RUN apt-get update && \
    apt-get install -y cron rclone sendemail libio-socket-ssl-perl libnet-ssleay-perl && \
    rm -rf /var/lib/apt/lists/*

VOLUME /backup

# Copy scripts and rclone config
COPY backup.sh /backup/backup.sh
COPY send_test_email.sh /backup/send_test_email.sh
COPY startup.sh /backup/startup.sh
COPY rclone.conf /root/.config/rclone/rclone.conf

# Make scripts executable
RUN chmod +x /backup/backup.sh /backup/send_test_email.sh /backup/startup.sh

# --- Add cron job here ---
# Write cron job to a cron file with environment variables preserved
RUN echo "0 2 * * * . /proc/1/environ; /backup/backup.sh >> /backup/backup.log 2>&1" > /etc/cron.d/mongo-backup

# Set correct permissions
RUN chmod 0644 /etc/cron.d/mongo-backup

# Apply the cron job
RUN crontab /etc/cron.d/mongo-backup
# --- Cron job setup done ---

# Start with our startup script that sends test email then starts cron
CMD ["/backup/startup.sh"]
