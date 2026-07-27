# Schema Management Scripts

This directory contains the database schema management scripts used by the `schema-server-job.yaml` Kubernetes Job.

## POSIX Compliance

**All scripts use POSIX-compliant `/bin/sh`** for maximum compatibility with minimal container images (Alpine, distroless, etc.).

- ✅ No bash-specific features (`[[`, `local`, arithmetic expansion)
- ✅ Works with busybox, dash, ash, and bash
- ✅ Suitable for Alpine-based images

## Structure

```
files/schema/
├── wait-cassandra.sh    # Wait for Cassandra to be ready
├── wait-postgres.sh     # Wait for PostgreSQL to be ready
├── wait-mysql.sh        # Wait for MySQL to be ready
├── setup-cassandra.sh   # Set up Cassandra schema
├── setup-postgres.sh    # Set up PostgreSQL schema
└── setup-mysql.sh       # Set up MySQL schema
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

Use ShellCheck to lint scripts (POSIX mode):

```bash
shellcheck -s sh ./*.sh
```

### Adding New Scripts

1. Create the script in `files/schema/`
2. Make it executable (optional, but good practice)
3. Helm will automatically include it in the ConfigMap
4. Update the Job template if needed to reference the new script

## Production Best Practices

### ✅ What This Implementation Provides

- **Separation of concerns** - Scripts are separate from Helm templates
- **Syntax highlighting** - Real `.sh` files in your editor
- **Linting** - Can run ShellCheck on actual shell scripts
- **Version control** - Scripts are versioned with the chart
- **Testability** - Can test scripts independently
- **Immutability** - Scripts are packaged into ConfigMap at install time
- **Visibility** - Can inspect scripts with `kubectl describe configmap`
