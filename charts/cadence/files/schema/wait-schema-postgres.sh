#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/postgres-utils.sh"

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

# Setup PostgreSQL environment
setup_postgres_env

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do
  echo 'PostgreSQL is not ready yet...'
  sleep 5
done
echo "PostgreSQL is ready!"

# Check schema versions in both databases
echo "Checking schema versions..."
echo "  Expected DEFAULT_VERSION: $DEFAULT_VERSION"
echo "  Expected VISIBILITY_VERSION: $VISIBILITY_VERSION"
echo "  ES_ENABLED: $ES_ENABLED"

ATTEMPT=0
until
  ATTEMPT=$((ATTEMPT + 1))
  echo "[Attempt $ATTEMPT] - Checking schema versions..."

  # Check main database schema version
  echo "  Querying main database ($DB_NAME)..."
  MAIN_OUTPUT=$($(build_psql_cmd) -d $DB_NAME -t -c "SELECT curr_version FROM schema_version WHERE db_name = '$DB_NAME';")
  MAIN_EXIT_CODE=$?
  MAIN_VERSION=$(echo "$MAIN_OUTPUT" | xargs)
  echo "    Query exit code: $MAIN_EXIT_CODE"
  echo "    Current version: '$MAIN_VERSION'"
  echo "    Expected version: '$DEFAULT_VERSION'"

  if [ $MAIN_EXIT_CODE -ne 0 ] || [ -z "$MAIN_VERSION" ]; then
    echo "    ERROR: Query failed or returned empty!"
    false
  elif echo "$MAIN_VERSION" | grep -q "$DEFAULT_VERSION"; then
    echo "    ✓ Main database version matches!"

    # Check visibility database schema version (only if ES is not enabled)
    if [ "$ES_ENABLED" = "false" ]; then
      echo "  Querying visibility database ($DB_VISIBILITY_NAME)..."
      VIS_OUTPUT=$($(build_psql_cmd) -d $DB_VISIBILITY_NAME -t -c "SELECT curr_version FROM schema_version WHERE db_name = '$DB_VISIBILITY_NAME';")
      VIS_EXIT_CODE=$?
      VIS_VERSION=$(echo "$VIS_OUTPUT" | xargs)
      echo "    Query exit code: $VIS_EXIT_CODE"
      echo "    Current version: '$VIS_VERSION'"
      echo "    Expected version: '$VISIBILITY_VERSION'"

      if [ $VIS_EXIT_CODE -ne 0 ] || [ -z "$VIS_VERSION" ]; then
        echo "    ERROR: Query failed or returned empty!"
        false
      elif echo "$VIS_VERSION" | grep -q "$VISIBILITY_VERSION"; then
        echo "    ✓ Visibility database version matches!"
        true
      else
        echo "    ✗ Visibility database version mismatch!"
        false
      fi
    else
      echo "  ✓ Skipping visibility database check (ES is enabled)"
      true
    fi
  else
    echo "    ✗ Main database version mismatch!"
    false
  fi
do
  echo "---"
  echo 'Schema not ready yet, waiting 10 seconds before retry...'
  sleep 10
done

echo "PostgreSQL schema is ready!"
