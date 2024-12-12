#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Load environment variables
source .env

# Configure AWS CLI
aws configure set aws_access_key_id "${AWS_ACCESS_KEY}"
aws configure set aws_secret_access_key "${AWS_SECRET_KEY}"
aws configure set region "${AWS_DEFAULT_REGION}"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Step 1: Dump the PostgreSQL database using the URI
echo "Dumping PostgreSQL database..."
DUMP_FILE="${BACKUP_DIR}/db_backup_$(date +%Y%m%d%H%M%S).sql.gz"
pg_dump "${POSTGRES_URI}" | gzip > "${DUMP_FILE}"

# Verify dump file exists
if [[ ! -f "${DUMP_FILE}" ]]; then
    echo "Backup failed: File not created."
    exit 1
fi

echo "Backup successful: ${DUMP_FILE}"

# Step 2: Upload to S3
echo "Uploading backup to S3..."
aws s3 cp "${DUMP_FILE}" "s3://${S3_BUCKET}/db_backups/"

if [[ $? -eq 0 ]]; then
    echo "Backup uploaded successfully to s3://${S3_BUCKET}/db_backups/$(basename ${DUMP_FILE})"
else
    echo "Failed to upload backup to S3."
    exit 1
fi

# Step 3: Cleanup old backups (optional, keeping only the last 7 backups)
echo "Cleaning up old backups..."
find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +7 -exec rm -f {} \;

echo "Backup and upload process completed."
