#!/bin/bash

# On first run overwrite secrets with env variables
DEFAULT_SECRETS_FILE="config/secrets.yml.default"
FINAL_SECRETS_FILE="config/secrets.yml"
if [[ -f "$DEFAULT_SECRETS_FILE" ]]; then
    SECRET=$(rails secret); sed -i "s/SECRET_KEY_BASE/$SECRET/g" "$DEFAULT_SECRETS_FILE"
    DEVISE_SECRET=$(rails secret); sed -i "s/DEVISE_SECRET_KEY/$DEVISE_SECRET/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/AWS_ACCESS_KEY_ID/$AWS_ACCESS_KEY_ID/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/AWS_SECRET_ACCESS_KEY/$AWS_SECRET_ACCESS_KEY/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/AWS_REGION/$AWS_REGION/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/SMTP_ADDRESS/$SMTP_ADDRESS/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/SMTP_PORT/$SMTP_PORT/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/SMTP_USER_NAME/$SMTP_USER_NAME/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/SMTP_PASSWORD/$SMTP_PASSWORD/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/SMTP_AUTHENTICATION/$SMTP_AUTHENTICATION/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/REDIS_SIDEKIQ_HOST/$REDIS_SIDEKIQ_HOST/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/REDIS_SIDEKIQ_PORT/$REDIS_SIDEKIQ_PORT/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/REDIS_CACHE_HOST/$REDIS_CACHE_HOST/g" "$DEFAULT_SECRETS_FILE"
    sed -i "s/REDIS_CACHE_PORT/$REDIS_CACHE_PORT/g" "$DEFAULT_SECRETS_FILE"
    mv "$DEFAULT_SECRETS_FILE" "$FINAL_SECRETS_FILE"
fi

# On first run overwrite db config with env variables
DEFAULT_DB_CONFIG_FILE="config/database.yml.default"
FINAL_DB_CONFIG_FILE="config/database.yml"
if [[ -f "$DEFAULT_DB_CONFIG_FILE" ]]; then
    sed -i "s/POSTGRES_HOST/$POSTGRES_HOST/g" "$DEFAULT_DB_CONFIG_FILE"
    sed -i "s/POSTGRES_PORT/$POSTGRES_PORT/g" "$DEFAULT_DB_CONFIG_FILE"
    sed -i "s/DB_NAME/$DB_NAME/g" "$DEFAULT_DB_CONFIG_FILE"
    sed -i "s/DB_USER/$DB_USER/g" "$DEFAULT_DB_CONFIG_FILE"
    sed -i "s/DB_PASSWORD/$DB_PASSWORD/g" "$DEFAULT_DB_CONFIG_FILE"
    mv "$DEFAULT_DB_CONFIG_FILE" "$FINAL_DB_CONFIG_FILE"
fi

# Compile the assets on first run
ASSETS_PRECOMPILED_FILE=".assets_precompiled"
if [[ ! -f "$ASSETS_PRECOMPILED_FILE" ]]; then
    bundle exec rails assets:precompile
    echo "assets precompiled" >> "$ASSETS_PRECOMPILED_FILE"
fi

# Update database if necessary
bundle exec rails db:migrate

# Create initial admin user
bundle exec rails runner script/create_user.rb "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "$ADMIN_USERNAME" true

# Start the server
bundle exec rails server
