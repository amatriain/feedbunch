#!/bin/bash

# Path in which rack-cache persists cache metadata
METADATA_PATH=/rack_cache/metastore
# Path in which rack-cache persists cache metadata
ENTITYDATA_PATH=/rack_cache/entitystore

# Maximum number of days of data to be kept in disk
MAX_DAYS=7

echo "deleting files older than $MAX_DAYS from $METADATA_PATH"
find $METADATA_PATH -mtime +$MAX_DAYS -exec rm -rf {} \;

echo "deleting files older than $MAX_DAYS from $ENTITYDATA_PATH"
find $ENTITYDATA_PATH -mtime +$MAX_DAYS -exec rm -rf {} \;
