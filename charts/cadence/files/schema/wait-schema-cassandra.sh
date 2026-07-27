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
echo "  Expected DEFAULT_VERSION: $DEFAULT_VERSION"
echo "  Expected VISIBILITY_VERSION: $VISIBILITY_VERSION"
echo "  ES_ENABLED: $ES_ENABLED"

ATTEMPT=0
until
  ATTEMPT=$((ATTEMPT + 1))
  echo "[Attempt $ATTEMPT] Checking schema versions..."

  # Check main keyspace schema version
  echo "  Querying main keyspace ($DB_NAME)..."
  MAIN_OUTPUT=$($(build_cqlsh_cmd) -e "EXPAND ON; USE $DB_NAME; SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_NAME';")
  MAIN_EXIT_CODE=$?
  MAIN_VERSION=$(echo "$MAIN_OUTPUT" | grep 'curr_version.*|' | cut -d'|' -f2 | xargs)
  echo "    Query exit code: $MAIN_EXIT_CODE"
  echo "    Current version: '$MAIN_VERSION'"
  echo "    Expected version: '$DEFAULT_VERSION'"

  if [ $MAIN_EXIT_CODE -ne 0 ] || [ -z "$MAIN_VERSION" ]; then
    echo "    ERROR: Query failed or returned empty!"
    false
  elif echo "$MAIN_VERSION" | grep -q "$DEFAULT_VERSION"; then
    echo "    ✓ Main keyspace version matches!"

    # Check visibility keyspace schema version (only if ES is not enabled)
    if [ "$ES_ENABLED" = "false" ]; then
      echo "  Querying visibility keyspace ($DB_VISIBILITY_NAME)..."
      VIS_OUTPUT=$($(build_cqlsh_cmd) -e "EXPAND ON; USE $DB_VISIBILITY_NAME; SELECT curr_version FROM schema_version WHERE keyspace_name = '$DB_VISIBILITY_NAME';")
      VIS_EXIT_CODE=$?
      VIS_VERSION=$(echo "$VIS_OUTPUT" | grep 'curr_version.*|' | cut -d'|' -f2 | xargs)
      echo "    Query exit code: $VIS_EXIT_CODE"
      echo "    Current version: '$VIS_VERSION'"
      echo "    Expected version: '$VISIBILITY_VERSION'"

      if [ $VIS_EXIT_CODE -ne 0 ] || [ -z "$VIS_VERSION" ]; then
        echo "    ERROR: Query failed or returned empty!"
        false
      elif echo "$VIS_VERSION" | grep -q "$VISIBILITY_VERSION"; then
        echo "    ✓ Visibility keyspace version matches!"
        true
      else
        echo "    ✗ Visibility keyspace version mismatch!"
        false
      fi
    else
      echo "  ✓ Skipping visibility keyspace check (ES is enabled)"
      true
    fi
  else
    echo "    ✗ Main keyspace version mismatch!"
    false
  fi
do
  echo "---"
  echo 'Schema not ready yet, waiting 10 seconds before retry...'
  sleep 10
done

echo "Cassandra schema is ready!"
