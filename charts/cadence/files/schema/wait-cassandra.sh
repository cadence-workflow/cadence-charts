#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/cassandra-utils.sh"

# Wait for Cassandra to be ready
wait_cassandra_ready
