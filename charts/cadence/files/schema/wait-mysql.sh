#!/bin/sh
set -e

# Source shared utilities from same directory as this script
. "$(dirname "$0")/mysql-utils.sh"

# Wait for MySQL to be ready
wait_mysql_ready
