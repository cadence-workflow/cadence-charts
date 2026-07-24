#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/cassandra-utils.sh"

# Wait for versions file from extract-schema-version init container
while [ ! -f /shared/schema-versions.env ]; do
  echo "Waiting for schema versions file..."
  sleep 2
done

# Load extracted versions
# shellcheck disable=SC2046
export $(cat /shared/schema-versions.env | xargs)
echo "Using extracted versions:"
echo "  DEFAULT_VERSION=$DEFAULT_VERSION"
echo "  VISIBILITY_VERSION=$VISIBILITY_VERSION"

# Build cqlshrc configuration
build_cqlshrc

# Check schema versions
echo "Checking Cassandra schema versions..."
until $(build_cqlsh_cmd) -e "
  USE $DB_NAME;
  SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_NAME';" | grep -q "$DEFAULT_VERSION" &&
  {
    if [ "$ES_ENABLED" = "false" ]; then
      $(build_cqlsh_cmd) -e "
        USE $DB_VISIBILITY_NAME;
        SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_VISIBILITY_NAME';" | grep -q "$VISIBILITY_VERSION"
    else
      true
    fi
  }
do
  echo 'Waiting for Cassandra schema to be ready...'
  sleep 10
done

echo "Cassandra schema is ready!"
