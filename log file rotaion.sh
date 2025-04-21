#!/bin/bash

# Define log directory and S3 bucket
LOG_DIR="/var/log"
S3_BUCKET="s3://your-bucket-name/log-archives/"
RETENTION_DAYS=7
CURRENT_DATE=$(date +%Y-%m-%d)
LOGS_ARCHIVE_DIR="/tmp/logs_archive"

# Create a directory to temporarily store archived logs
mkdir -p $LOGS_ARCHIVE_DIR

# Find and compress logs older than 7 days
find $LOG_DIR -type f -mtime +$RETENTION_DAYS -name "*.log" | while read LOG_FILE; do
  # Compress the log file
  LOG_FILE_NAME=$(basename "$LOG_FILE")
  gzip -c "$LOG_FILE" > "$LOGS_ARCHIVE_DIR/$LOG_FILE_NAME.gz"
  
  # Upload the compressed log to S3
  aws s3 cp "$LOGS_ARCHIVE_DIR/$LOG_FILE_NAME.gz" "$S3_BUCKET$CURRENT_DATE/$LOG_FILE_NAME.gz"
  
  # If upload is successful, delete the local log
  if [ $? -eq 0 ]; then
    rm -f "$LOG_FILE"
    echo "Successfully archived and deleted: $LOG_FILE"
  else
    echo "Failed to upload: $LOG_FILE"
  fi
done

# Clean up temporary archive directory
rm -rf $LOGS_ARCHIVE_DIR
