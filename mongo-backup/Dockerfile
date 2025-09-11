FROM mongo:latest

# Install cron, rclone, sendemail, and dependencies
RUN apt-get update && \
    apt-get install -y cron rclone sendemail libio-socket-ssl-perl libnet-ssleay-perl && \
    rm -rf /var/lib/apt/lists/*

# Copy scripts to /usr/local/bin and rclone config
COPY backup.sh /usr/local/bin/backup.sh
COPY send_test_email.sh /usr/local/bin/send_test_email.sh
COPY startup.sh /usr/local/bin/startup.sh
COPY rclone.conf /root/.config/rclone/rclone.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/send_test_email.sh /usr/local/bin/startup.sh

VOLUME /backup

# --- Add cron job here ---
# Write cron job to a cron file with environment variables preserved
RUN echo "0 2 * * * . /proc/1/environ; /usr/local/bin/backup.sh >> /backup/backup.log 2>&1" > /etc/cron.d/mongo-backup

# Set correct permissions
RUN chmod 0644 /etc/cron.d/mongo-backup

# Apply the cron job
RUN crontab /etc/cron.d/mongo-backup
# --- Cron job setup done ---

# Override the entrypoint to use our startup script
ENTRYPOINT ["/usr/local/bin/startup.sh"]
