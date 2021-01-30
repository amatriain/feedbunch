#!/bin/bash

# On first run overwrite config with env variables
REDIS_CONF_DIR="/usr/local/etc/redis"
DEFAULT_CONFIG_FILE="redis.conf.default"
FINAL_CONFIG_FILE="redis.conf"

cd "$REDIS_CONF_DIR"
if [[ -f "$DEFAULT_CONFIG_FILE" ]]; then
    sed -i "s/REDIS_CACHE_PORT/$REDIS_CACHE_PORT/g" "$DEFAULT_CONFIG_FILE"
    sed -i "s/REDIS_CACHE_MAXCLIENTS/$REDIS_CACHE_MAXCLIENTS/g" "$DEFAULT_CONFIG_FILE"
    sed -i "s/REDIS_CACHE_MAXMEMORY/$REDIS_CACHE_MAXMEMORY/g" "$DEFAULT_CONFIG_FILE"
    mv "$DEFAULT_CONFIG_FILE" "$FINAL_CONFIG_FILE"
fi

# Start redis
redis-server ./"$FINAL_CONFIG_FILE"
