# Dockerfile to build an image for the FeedBunch redis cache (to cache web gui fragments)

FROM redis:6.0.9

# Env vars with default values that the user can change
ENV REDIS_CACHE_PORT=6380
ENV REDIS_CACHE_MAXCLIENTS=128
ENV REDIS_CACHE_MAXMEMORY="128Mb"

# Redis server port
EXPOSE $REDIS_CACHE_PORT/tcp

# Volume for persistence
VOLUME /data

# Redis config in /usr/local/etc/redis/redis.conf
COPY ./config/redis.conf.default /usr/local/etc/redis/redis.conf.default
COPY start_feedbunch_redis_cache.sh .

# Fix permissions
RUN chmod +x start_feedbunch_redis_cache.sh

ENTRYPOINT ["bash", "start_feedbunch_redis_cache.sh"]
