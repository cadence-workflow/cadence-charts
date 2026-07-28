#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/mysql-utils.sh"

# Wait for versions file from extract-schema-version init container
while [ ! -f /shared/schema-versions.env ]; do
  echo "Waiting for schema versions file..."
  sleep 2
done

# Load extracted versions
set -a
. /shared/schema-versions.env
set +a
echo "Using extracted versions:"
echo "  DEFAULT_VERSION=$DEFAULT_VERSION"
echo "  VISIBILITY_VERSION=$VISIBILITY_VERSION"

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
if [ -n "$MYSQL_PWD" ]; then
  until mariadb-admin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$MYSQL_PWD" --skip-ssl --silent; do
    echo 'MySQL is not ready yet...'
    sleep 5
  done
else
  until mariadb-admin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --skip-ssl --silent; do
    echo 'MySQL is not ready yet...'
    sleep 5
  done
fi
echo "MySQL is ready!"

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
  MAIN_OUTPUT=$($(build_mysql_cmd) -D "$DB_NAME" -e "SELECT curr_version FROM schema_version WHERE db_name = '$DB_NAME';")
  MAIN_EXIT_CODE=$?
  MAIN_VERSION=$(echo "$MAIN_OUTPUT" | grep -v "curr_version" | xargs)
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
      VIS_OUTPUT=$($(build_mysql_cmd) -D "$DB_VISIBILITY_NAME" -e "SELECT curr_version FROM schema_version WHERE db_name = '$DB_VISIBILITY_NAME';")
      VIS_EXIT_CODE=$?
      VIS_VERSION=$(echo "$VIS_OUTPUT" | grep -v "curr_version" | xargs)
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

echo "MySQL schema is ready!"
