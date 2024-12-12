# Use a lightweight image with PostgreSQL client tools
FROM debian:bullseye-slim

# Install PostgreSQL client tools and AWS CLI
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    awscli \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y postgresql-client-17 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the backup script into the container
COPY ./backup.sh ./
COPY ./.env ./

# Make the script executable
RUN chmod +x ./backup.sh

# Default command
CMD ["./backup.sh"]
