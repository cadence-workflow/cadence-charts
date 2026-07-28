# Schema Management Scripts

This directory contains the database schema management scripts used by the `schema-server-job.yaml` Kubernetes Job.

## POSIX Compliance

**All scripts use POSIX-compliant `/bin/sh`** for maximum compatibility with minimal container images (Alpine, distroless, etc.).

- ✅ No bash-specific features (`[[`, `local`, arithmetic expansion)
- ✅ Works with busybox, dash, ash, and bash
- ✅ Suitable for Alpine-based images
- ✅ All scripts pass shellcheck validation
- ✅ Automated shellcheck runs on every PR via GitHub Actions

## Structure

```
files/schema/
├── *-utils.sh                       # Shared utility functions
│   ├── cassandra-utils.sh           # Cassandra connection utilities
│   ├── elasticsearch-utils.sh       # Elasticsearch connection utilities
│   ├── mysql-utils.sh               # MySQL connection utilities
│   └── postgres-utils.sh            # PostgreSQL connection utilities
├── wait-*.sh                        # Database readiness checks
│   ├── wait-cassandra.sh            # Wait for Cassandra to be ready
│   ├── wait-elasticsearch.sh        # Wait for Elasticsearch to be ready
│   ├── wait-mysql.sh                # Wait for MySQL to be ready
│   └── wait-postgres.sh             # Wait for PostgreSQL to be ready
├── wait-schema-*.sh                 # Schema version validation
│   ├── wait-schema-cassandra.sh     # Wait for Cassandra schema version
│   ├── wait-schema-mysql.sh         # Wait for MySQL schema version
│   └── wait-schema-postgres.sh      # Wait for PostgreSQL schema version
├── setup-*.sh                       # Schema setup scripts
│   ├── setup-cassandra.sh           # Set up Cassandra schema
│   ├── setup-elasticsearch.sh       # Set up Elasticsearch schema
│   ├── setup-mysql.sh               # Set up MySQL schema
│   └── setup-postgres.sh            # Set up PostgreSQL schema
└── check-*.sh                       # Schema validation scripts
    └── check-elasticsearch-schema.sh # Validate Elasticsearch schema
```

## Development

### Testing Scripts Locally

You can test scripts locally using Docker:

```bash
# Test Cassandra wait script
docker run --rm -v $(pwd)/files/schema:/scripts \
  -e DB_HOST=cassandra.example.com \
  -e DB_PORT=9042 \
  -e TLS_ENABLED=false \
  cassandra:4.1 \
  /bin/bash /scripts/wait-cassandra.sh

# Test PostgreSQL setup script
docker run --rm -v $(pwd)/files/schema:/scripts \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=cadence \
  -e DB_NAME=cadence \
  -e DB_VISIBILITY_NAME=cadence_visibility \
  -e ES_ENABLED=false \
  -e CADENCE_HOME=/etc/cadence \
  ubercadence/cadence:latest \
  /bin/bash /scripts/setup-postgres.sh
```

### Linting

All scripts are validated with ShellCheck in POSIX sh mode:

```bash
# Lint all scripts (POSIX sh mode)
shellcheck -s sh files/schema/*.sh

# Lint with warnings only (matches CI)
shellcheck -s sh -S warning files/schema/*.sh

# Lint with GCC format (for IDE integration)
shellcheck -s sh -f gcc files/schema/*.sh
```

**GitHub Actions**: Shellcheck runs automatically on every push and PR. See `.github/workflows/shellcheck.yml`.

**Important Notes**:
- `CURL_OPTS` is intentionally unquoted in Elasticsearch scripts - it's a space-separated string that must be word-split
- SC1091 (info) warnings about sourced files are expected and can be ignored
- All other warnings and errors must be fixed before merging

### Adding New Scripts

1. Create the script in `files/schema/`
2. Start with the POSIX shebang: `#!/bin/sh`
3. Add `set -e` to exit on errors
4. Validate with shellcheck: `shellcheck -s sh your-script.sh`
5. Helm will automatically include it in the ConfigMap
6. Update the Job template if needed to reference the new script

### Code Quality Standards

All scripts must:
- Use POSIX sh syntax only (no bash-isms)
- Pass `shellcheck -s sh` with no warnings or errors
- Use `set -e` to fail fast on errors

## Production Best Practices

### ✅ What This Implementation Provides

- **Separation of concerns** - Scripts are separate from Helm templates
- **Syntax highlighting** - Real `.sh` files in your editor
- **Linting** - Can run ShellCheck on actual shell scripts
- **Version control** - Scripts are versioned with the chart
- **Testability** - Can test scripts independently
- **Immutability** - Scripts are packaged into ConfigMap at install time
- **Visibility** - Can inspect scripts with `kubectl describe configmap`
