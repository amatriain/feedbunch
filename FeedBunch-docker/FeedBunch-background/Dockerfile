# Dockerfile to build an image for the FeedBunch sidekiq app
FROM ruby:2.7.2

# Change when FeedBunch latest tag changes
ENV FEEDBUNCH_TAG=master
ARG FEEDBUNCH_URL=https://gitlab.com/amatriain/feedbunch.git

# Env vars with default values that the user can change
ENV ADMIN_EMAIL=some@email.com
ENV DEMO_USER_ENABLED=false
ENV SIGNUPS_ENABLED=false
ENV UPLOADS_LOCATION=local
ENV AWS_ACCESS_KEY_ID=aws_access_key_id
ENV AWS_SECRET_ACCESS_KEY=aws_secret_access_key
ENV AWS_REGION=aws_region
ENV AWS_S3_BUCKET=feedbunch-production
ENV SMTP_ADDRESS=smtp.gmail.com
ENV SMTP_PORT=587
ENV SMTP_USER_NAME=gmail_user
ENV SMTP_PASSWORD=gmail_password
ENV SMTP_AUTHENTICATION=plain
ENV EMAIL_LINKS_URL='https://www.feedbunch.com'
ENV REDIS_SIDEKIQ_HOST=localhost
ENV REDIS_SIDEKIQ_PORT=6379
ENV POSTGRES_HOST=localhost
ENV POSTGRES_PORT=5432
ENV DB_NAME=feedbunch
ENV DB_USER=feedbunch
ENV DB_PASSWORD=feedbunch
ENV HEADLESS_BROWSER_HOST=127.0.0.1
ENV HEADLESS_BROWSER_PORT=4444

# Env vars to be picked by Rails, not intended to be changed
ENV LANG C.UTF-8
ENV RAILS_ENV=production
ENV FEEDBUNCH_LOG_LEVEL=debug
ENV APP_DIR=/home/feedbunch_background/feedbunch/FeedBunch-app
ENV STDOUT_FILE=/dev/stdout
ENV STDERR_FILE=/dev/stderr
ENV RAILS_LOG_TO_STDOUT=true
ENV HEADLESS_BROWSER_LOCATION=remote

# Install needed packages
RUN set -eux \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y \
        git \ 
        nodejs \
    && rm -rf /var/lib/apt/lists/*
    
# Create unprivileged user feedbunch_background
RUN adduser --disabled-login --gecos '' feedbunch_background

# FeedBunch installed to the feedbunch_background user's home
WORKDIR /home/feedbunch_background

# Get FeedBunch app files from git repo
RUN git clone $FEEDBUNCH_URL
WORKDIR $APP_DIR
RUN git checkout -q $FEEDBUNCH_TAG

# Copy FeedBunch additional files
COPY ./config/database.yml.default ./config/database.yml.default
COPY ./config/secrets.yml.default ./config/secrets.yml.default
COPY start_feedbunch_background.sh .

# Create folders where volumes will be mounted, so permissions are preserved
RUN mkdir $APP_DIR/opml_imports
RUN mkdir $APP_DIR/opml_exports

# Fix permissions
RUN chown -R feedbunch_background:feedbunch_background /home/feedbunch_background
RUN chmod +x start_feedbunch_background.sh

# Volume shared with the feedbunch-webapp container, for local OPML uploads
VOLUME $APP_DIR/opml_imports

# Volume shared with the feedbunch-webapp container, for local OPML downloads
VOLUME $APP_DIR/opml_exports

# Volume for files cached by rack-cache
VOLUME $APP_DIR/rack_cache

# Install gems
USER feedbunch_background
RUN bundle config --global frozen 1
RUN bundle config set without 'ci development test'
RUN bundle install

ENTRYPOINT ["bash", "start_feedbunch_background.sh"]
