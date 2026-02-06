FROM mongo:latest

# Metadata
LABEL maintainer="Antigravity"
LABEL description="MongoDB image with automated backup restore from .tar.gz on initialization"

# Install tar/gzip
RUN apt-get update && apt-get install -y tar gzip && rm -rf /var/lib/apt/lists/*

# Create directory for backups inside root
RUN mkdir -p /backups

# Copy initialization scripts
# The official mongo image executes .sh and .js files in /docker-entrypoint-initdb.d
COPY init/ /docker-entrypoint-initdb.d/

# Copy the specific backup file into the image
COPY backup.tar.gz /backups/

# Ensure scripts are executable
RUN chmod +x /docker-entrypoint-initdb.d/restore.sh
