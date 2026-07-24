#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/postgres-utils.sh"

# Wait for PostgreSQL to be ready
wait_postgres_ready
