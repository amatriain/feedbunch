# Dockerfile to build an image that runs cron jobs in a FeedBunch stack
FROM debian:stable-slim

# Volume for files cached by rack-cache
VOLUME /rack_cache

# Install needed packages
RUN set -eux \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y \
        cron \
    && rm -rf /var/lib/apt/lists/*

# Copy crontab definition and script to run periodically on /cron
WORKDIR /cron
COPY ./cron.txt .
COPY cleanup_old_rack_cache.sh .

# Fix permissions
RUN chmod 0600 cron.txt
RUN chmod +x cleanup_old_rack_cache.sh

# Install crontab
RUN crontab cron.txt

ENTRYPOINT ["cron", "-f"]