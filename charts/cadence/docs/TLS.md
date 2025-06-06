# TLS Configuration for Cassandra

This document describes how to configure TLS (Transport Layer Security) for secure connections to Cassandra.

## Configuration Overview

The TLS configuration supports multiple security scenarios from basic server authentication to full mutual TLS (mTLS).

### Basic Configuration

```yaml
tls:
  enabled: true
  caFile: "/path/to/ca-cert.pem"
  enableHostVerification: true
```

## Configuration Parameters

### `enabled`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enables or disables TLS connections
- **Usage**: When `false`, all other TLS settings are ignored

### `caFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to Certificate Authority (CA) certificate file
- **Format**: PEM format
- **Usage**: Required to verify server certificates and establish trust
- **Example**: `"/etc/ssl/certs/ca-certificates.crt"`

### `caFiles`
- **Type**: `array`
- **Default**: `[]`
- **Description**: Array of CA certificate file paths
- **Format**: PEM format
- **Usage**: Alternative to `caFile` when multiple CA certificates are needed
- **Note**: Can be used together with `caFile` - all certificates are combined
- **Example**: `["/path/to/ca1.pem", "/path/to/ca2.pem"]`

### `certFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to client certificate file
- **Format**: PEM format
- **Usage**: Required for mutual TLS (mTLS) authentication
- **Dependencies**: Must be used together with `keyFile`
- **Example**: `"/path/to/client-cert.pem"`

### `keyFile`
- **Type**: `string`
- **Default**: `""`
- **Description**: Path to client private key file
- **Format**: PEM format (RSA or ECDSA)
- **Usage**: Required for mutual TLS (mTLS) authentication
- **Dependencies**: Must be used together with `certFile`
- **Security**: Should have restricted file permissions (600)
- **Example**: `"/path/to/client-key.pem"`

### `enableHostVerification`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enables hostname verification against server certificate
- **Security**: 
  - `true`: Verifies server certificate matches hostname (secure)
  - `false`: Skips hostname verification (insecure - testing only)
- **Recommendation**: Always `true` in production environments

### `requireClientAuth`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Requires client certificate authentication (mutual TLS)
- **Usage**: When `true`, server will request and verify client certificates
- **Dependencies**: Clients must provide `certFile` and `keyFile`
- **Server requirement**: Cassandra server must be configured for mTLS

### `serverName`
- **Type**: `string`
- **Default**: `""`
- **Description**: Override server name for certificate verification
- **Usage**: Use when connecting via IP address or when certificate Common Name differs from hostname
- **Example**: `"cassandra.example.com"` when connecting to `192.168.1.100`

## Certificate Formats

### PEM Format
- **Description**: Privacy-Enhanced Mail format (Base64 encoded, human-readable)
- **Extensions**: `.pem`, `.crt`, `.cer`, `.key`
- **Structure**: Contains `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` headers
- **Support**: Only format supported by this implementation

## Configuration Scenarios

### 1. Basic TLS (Server Authentication Only)

**Use case**: Encrypt data in transit and verify server identity

```yaml
tls:
  enabled: true
  caFile: "/path/to/ca-cert.pem"
  enableHostVerification: true
```

**Requirements**:
- CA certificate that signed the server certificate
- Server certificate must match hostname

### 2. Mutual TLS (Bidirectional Authentication)

**Use case**: High-security environments requiring both server and client authentication

```yaml
tls:
  enabled: true
  caFile: "/path/to/ca-cert.pem"
  certFile: "/path/to/client-cert.pem"
  keyFile: "/path/to/client-key.pem"
  requireClientAuth: true
  enableHostVerification: true
```

**Requirements**:
- CA certificate
- Client certificate and private key
- Server configured for mutual TLS
- Client certificate must be signed by CA trusted by server

### 3. Multiple CA Certificates

**Use case**: Connecting to multiple Cassandra clusters with different CAs

```yaml
tls:
  enabled: true
  caFiles:
    - "/path/to/ca1.pem"
    - "/path/to/ca2.pem"
  enableHostVerification: true
```

### 4. Development/Testing with Self-signed Certificates

**Use case**: Testing environment with self-signed certificates

```yaml
tls:
  enabled: true
  caFile: "/path/to/self-signed-ca.pem"
  enableHostVerification: false  # Only if hostname doesn't match
  serverName: "cassandra.local"   # If needed for verification
```

**⚠️ Warning**: Only use `enableHostVerification: false` in development environments

### 5. IP Address Connections

**Use case**: Connecting via IP address when certificate contains hostname

```yaml
tls:
  enabled: true
  caFile: "/path/to/ca-cert.pem"
  serverName: "cassandra.example.com"  # Actual hostname in certificate
  enableHostVerification: true
```

## Security Best Practices

### Production Environments
- Always use `enableHostVerification: true`
- Use certificates from trusted Certificate Authorities
- Regularly rotate certificates before expiration
- Use mutual TLS for high-security requirements

### File Permissions
- Private key files should have restricted permissions:
  ```bash
  chmod 600 /path/to/client-key.pem
  ```
- Certificate files can be readable:
  ```bash
  chmod 644 /path/to/client-cert.pem
  chmod 644 /path/to/ca-cert.pem
  ```

### Certificate Management
- Monitor certificate expiration dates
- Implement automated certificate renewal
- Keep CA certificates up to date
- Use separate certificates for different environments

## Troubleshooting

### Common Issues

1. **Certificate verification failed**
   - Check if CA certificate is correct
   - Verify certificate chain is complete
   - Ensure certificate hasn't expired

2. **Hostname verification failed**
   - Verify server certificate contains correct hostname/SAN
   - Use `serverName` to override hostname verification
   - Consider using `enableHostVerification: false` only for testing

3. **Client certificate required**
   - Ensure `certFile` and `keyFile` are provided
   - Verify client certificate is signed by trusted CA
   - Check if `requireClientAuth` is correctly configured

4. **Connection refused**
   - Verify TLS is enabled on Cassandra server
   - Check if server is listening on TLS port
   - Confirm firewall allows TLS traffic

### Validation Commands

Test certificate validity:
```bash
# Check certificate details
openssl x509 -in /path/to/cert.pem -text -noout

# Verify certificate chain
openssl verify -CAfile /path/to/ca.pem /path/to/cert.pem

# Test TLS connection
openssl s_client -connect cassandra-host:9142 -CAfile /path/to/ca.pem
```

## Integration with Cassandra

### Server-side Configuration
Ensure your Cassandra server is configured for TLS:

```yaml
# cassandra.yaml
client_encryption_options:
  enabled: true
  optional: false
  keystore: /path/to/server-keystore.jks
  keystore_password: password
  truststore: /path/to/server-truststore.jks
  truststore_password: password
  require_client_auth: false  # Set to true for mutual TLS
```

### Port Configuration
- Default Cassandra native protocol port: `9042`
- Default Cassandra TLS port: `9142`
- Ensure your application connects to the correct port when TLS is enabled