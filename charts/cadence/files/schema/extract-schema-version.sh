#!/bin/sh
set -e

if [ -f "$VERSION_FILE" ]; then
  default_version=$(grep 'const Version' "$VERSION_FILE" | awk -F'"' '{print $2}')
  visibility_version=$(grep 'const VisibilityVersion' "$VERSION_FILE" | awk -F'"' '{print $2}')

  echo "DEFAULT_VERSION=$default_version" > /shared/schema-versions.env
  echo "VISIBILITY_VERSION=$visibility_version" >> /shared/schema-versions.env

  echo "Extracted versions:"
  echo "  DEFAULT_VERSION=$default_version"
  echo "  VISIBILITY_VERSION=$visibility_version"
else
  echo "Error: version.go file not found at $VERSION_FILE"
  exit 1
fi
