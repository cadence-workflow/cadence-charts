#!/bin/sh
set -e

echo "Starting Elasticsearch readiness check..."

# Source shared utilities from same directory as this script
. "$(dirname "$0")/elasticsearch-utils.sh"

# Build Elasticsearch connection parameters
build_es_connection

# Check Elasticsearch health
until curl $CURL_OPTS -s -f "$BASE_URL/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null; do
    echo "Elasticsearch is not ready yet..."
    sleep 10
done

# Cleanup
cleanup_es_connection

echo "Elasticsearch is ready!"
