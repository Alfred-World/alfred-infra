# mTLS Certificates for Alfred Microservices

This directory contains the certificate infrastructure for mutual TLS (mTLS) authentication between services.

## Directory Structure

```
certificates/
├── ca/                     # Certificate Authority
│   ├── ca.crt             # CA public certificate (shared with all services)
│   └── ca.key             # CA private key (HIGHLY SENSITIVE - keep secure!)
├── gateway/               # Gateway client certificate
│   ├── gateway-client.crt # Client certificate
│   ├── gateway-client.key # Private key
│   ├── gateway-client.pfx # PKCS#12 bundle for .NET
│   └── gateway.cnf        # OpenSSL config
├── alfred-identity/       # Identity service server certificate
│   ├── identity.crt       # Server certificate
│   ├── identity.key       # Private key
│   ├── identity.pfx       # PKCS#12 bundle for .NET
│   └── identity.cnf       # OpenSSL config
├── alfred-core/           # Core service server certificate
│   ├── core.crt           # Server certificate
│   ├── core.key           # Private key
│   ├── core.pfx           # PKCS#12 bundle for .NET
│   └── core.cnf           # OpenSSL config
├── generate-certs.sh      # Certificate generation script
├── .gitignore             # Ignores private keys
└── README.md              # This file
```

## Quick Start

### 1. Generate Certificates

```bash
cd alfred-infra/certificates
chmod +x generate-certs.sh
./generate-certs.sh
```

This generates:
- CA certificate with 10-year validity
- Gateway client certificate for calling backend services
- Server certificates for Identity and Core services

### 2. Enable mTLS in Docker Compose

Edit `.env.prod`:

```env
MTLS_ENABLED=true
```

### 3. Deploy

```bash
cd alfred-infra
docker-compose -f docker-compose.prod.yml up -d
```

## How mTLS Works

```
┌─────────────┐                    ┌──────────────────┐
│   Gateway   │  ──── HTTPS ────>  │  Backend Service │
│             │   (with client     │                  │
│ Presents:   │    certificate)    │ Validates:       │
│ - Client    │                    │ - Client cert is │
│   Cert      │<──── Response ──── │   signed by CA   │
└─────────────┘                    └──────────────────┘
```

1. **Gateway** initiates HTTPS connection to backend service
2. **Gateway** presents its client certificate (`gateway-client.pfx`)
3. **Backend** validates the client certificate is signed by trusted CA
4. If valid, request proceeds; otherwise, connection is rejected

## Security Notes

⚠️ **IMPORTANT**: Never commit private keys (`.key`, `.pfx`) to version control!

The `.gitignore` file is configured to:
- ✅ Allow `.crt` files (public certificates)
- ✅ Allow `.cnf` files (OpenSSL configs)
- ❌ Ignore `.key` files (private keys)
- ❌ Ignore `.pfx` files (PKCS#12 bundles with private keys)
- ❌ Ignore `.csr` files (certificate signing requests)

## Certificate Validity

All certificates are generated with **10-year validity** (3650 days) for convenience.

For production environments with stricter security requirements, consider:
- Shorter validity periods (90 days - 1 year)
- Automated certificate rotation
- Using a proper PKI solution (HashiCorp Vault, AWS ACM, etc.)

## Environment Variables

### Backend Services (Identity, Core)

| Variable | Description | Default |
|----------|-------------|---------|
| `MTLS_ENABLED` | Enable mTLS | `false` |
| `MTLS_SERVER_CERT_PATH` | Path to server PFX | - |
| `MTLS_SERVER_CERT_PASSWORD` | PFX password | `""` |
| `MTLS_CA_CERT_PATH` | Path to CA certificate | - |
| `MTLS_HTTPS_PORT` | HTTPS port | `8101` / `8201` |
| `MTLS_HTTP_PORT` | HTTP port (health checks) | `8100` / `8200` |
| `MTLS_ALLOW_HTTP` | Allow HTTP endpoint | `true` |

### Gateway

| Variable | Description | Default |
|----------|-------------|---------|
| `MTLS_ENABLED` | Enable mTLS | `false` |
| `MTLS_CLIENT_CERT_PATH` | Path to client PFX | - |
| `MTLS_CLIENT_CERT_PASSWORD` | PFX password | `""` |
| `MTLS_CA_CERT_PATH` | Path to CA certificate | - |
| `MTLS_SKIP_SERVER_CERT_VALIDATION` | Skip validation (dev only) | `false` |

## Troubleshooting

### Certificate validation failed

Check that:
1. All certificates are signed by the same CA
2. CA certificate is correctly mounted in containers
3. Certificate paths in environment variables are correct

### Connection refused

Check that:
1. Backend services are listening on HTTPS port (8101, 8201)
2. YARP is configured to use HTTPS URLs
3. `MTLS_ENABLED=true` is set for all services

### Debug certificate chain

```bash
# Verify certificate
openssl x509 -in alfred-identity/identity.crt -text -noout

# Verify certificate is signed by CA
openssl verify -CAfile ca/ca.crt alfred-identity/identity.crt

# Test HTTPS connection with client cert
openssl s_client -connect localhost:8101 \
  -cert gateway/gateway-client.crt \
  -key gateway/gateway-client.key \
  -CAfile ca/ca.crt
```

## Regenerating Certificates

To regenerate all certificates:

```bash
# Remove old certificates
rm -rf ca gateway alfred-identity alfred-core

# Regenerate
./generate-certs.sh
```

**Note**: After regenerating, you must restart all Docker containers:

```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```
