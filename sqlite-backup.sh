#!/bin/bash

# Set the volume name and backup directory
VOLUME_NAME="cabuca_sqlite-data"
BACKUP_DIR="/var/lib/docker/volumes/cabuca_sqlite-data/_data"

# Get the mountpoint of the volume
MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' $VOLUME_NAME)

# Create a timestamp for the backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create the backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Copy the volume data to the backup directory
sudo cp -r $MOUNTPOINT $BACKUP_DIR/backup_$TIMESTAMP

# Verify the backup
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_DIR/backup_$TIMESTAMP"
else
    echo "Backup failed"
fi
