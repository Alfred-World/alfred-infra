#!/bin/bash

# ==============================================================================
# mTLS Certificate Generation Script for Alfred Microservices
# Generates CA, Server, and Client certificates with 10-year validity
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDITY_DAYS=3650  # 10 years

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Alfred mTLS Certificate Generator   ${NC}"
echo -e "${GREEN}========================================${NC}"

# Create directories
mkdir -p "$SCRIPT_DIR/ca"
mkdir -p "$SCRIPT_DIR/gateway"
mkdir -p "$SCRIPT_DIR/alfred-identity"
mkdir -p "$SCRIPT_DIR/alfred-core"

# ==============================================================================
# 1. Generate CA Certificate (Certificate Authority)
# ==============================================================================
echo -e "\n${YELLOW}[1/4] Generating CA Certificate...${NC}"

if [ ! -f "$SCRIPT_DIR/ca/ca.key" ]; then
    # Generate CA private key
    openssl genrsa -out "$SCRIPT_DIR/ca/ca.key" 4096

    # Generate CA certificate
    openssl req -x509 -new -nodes \
        -key "$SCRIPT_DIR/ca/ca.key" \
        -sha256 \
        -days $VALIDITY_DAYS \
        -out "$SCRIPT_DIR/ca/ca.crt" \
        -subj "/C=VN/ST=HoChiMinh/L=HoChiMinh/O=Alfred/OU=Infrastructure/CN=Alfred Internal CA"

    echo -e "${GREEN}✓ CA Certificate generated${NC}"
else
    echo -e "${YELLOW}⚠ CA Certificate already exists, skipping...${NC}"
fi

# ==============================================================================
# 2. Generate Gateway Client Certificate (for calling backend services)
# ==============================================================================
echo -e "\n${YELLOW}[2/4] Generating Gateway Client Certificate...${NC}"

# Create OpenSSL config for gateway
cat > "$SCRIPT_DIR/gateway/gateway.cnf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = VN
ST = HoChiMinh
L = HoChiMinh
O = Alfred
OU = Gateway
CN = alfred-gateway

[req_ext]
subjectAltName = @alt_names
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth

[alt_names]
DNS.1 = alfred-gateway
DNS.2 = localhost
DNS.3 = gateway.alfred.local
EOF

# Generate private key
openssl genrsa -out "$SCRIPT_DIR/gateway/gateway-client.key" 2048

# Generate CSR
openssl req -new \
    -key "$SCRIPT_DIR/gateway/gateway-client.key" \
    -out "$SCRIPT_DIR/gateway/gateway-client.csr" \
    -config "$SCRIPT_DIR/gateway/gateway.cnf"

# Sign with CA
openssl x509 -req \
    -in "$SCRIPT_DIR/gateway/gateway-client.csr" \
    -CA "$SCRIPT_DIR/ca/ca.crt" \
    -CAkey "$SCRIPT_DIR/ca/ca.key" \
    -CAcreateserial \
    -out "$SCRIPT_DIR/gateway/gateway-client.crt" \
    -days $VALIDITY_DAYS \
    -sha256 \
    -extensions req_ext \
    -extfile "$SCRIPT_DIR/gateway/gateway.cnf"

# Create PFX (PKCS#12) for .NET - without password for simplicity
openssl pkcs12 -export \
    -out "$SCRIPT_DIR/gateway/gateway-client.pfx" \
    -inkey "$SCRIPT_DIR/gateway/gateway-client.key" \
    -in "$SCRIPT_DIR/gateway/gateway-client.crt" \
    -certfile "$SCRIPT_DIR/ca/ca.crt" \
    -passout pass:

echo -e "${GREEN}✓ Gateway Client Certificate generated${NC}"

# ==============================================================================
# 3. Generate Alfred Identity Server Certificate
# ==============================================================================
echo -e "\n${YELLOW}[3/4] Generating Alfred Identity Server Certificate...${NC}"

# Create OpenSSL config for identity service
cat > "$SCRIPT_DIR/alfred-identity/identity.cnf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = VN
ST = HoChiMinh
L = HoChiMinh
O = Alfred
OU = Identity
CN = alfred-identity

[req_ext]
subjectAltName = @alt_names
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[alt_names]
DNS.1 = alfred-identity
DNS.2 = localhost
DNS.3 = identity.alfred.local
IP.1 = 127.0.0.1
EOF

# Generate private key
openssl genrsa -out "$SCRIPT_DIR/alfred-identity/identity.key" 2048

# Generate CSR
openssl req -new \
    -key "$SCRIPT_DIR/alfred-identity/identity.key" \
    -out "$SCRIPT_DIR/alfred-identity/identity.csr" \
    -config "$SCRIPT_DIR/alfred-identity/identity.cnf"

# Sign with CA
openssl x509 -req \
    -in "$SCRIPT_DIR/alfred-identity/identity.csr" \
    -CA "$SCRIPT_DIR/ca/ca.crt" \
    -CAkey "$SCRIPT_DIR/ca/ca.key" \
    -CAcreateserial \
    -out "$SCRIPT_DIR/alfred-identity/identity.crt" \
    -days $VALIDITY_DAYS \
    -sha256 \
    -extensions req_ext \
    -extfile "$SCRIPT_DIR/alfred-identity/identity.cnf"

# Create PFX for .NET
openssl pkcs12 -export \
    -out "$SCRIPT_DIR/alfred-identity/identity.pfx" \
    -inkey "$SCRIPT_DIR/alfred-identity/identity.key" \
    -in "$SCRIPT_DIR/alfred-identity/identity.crt" \
    -certfile "$SCRIPT_DIR/ca/ca.crt" \
    -passout pass:

echo -e "${GREEN}✓ Alfred Identity Server Certificate generated${NC}"

# ==============================================================================
# 4. Generate Alfred Core Server Certificate
# ==============================================================================
echo -e "\n${YELLOW}[4/4] Generating Alfred Core Server Certificate...${NC}"

# Create OpenSSL config for core service
cat > "$SCRIPT_DIR/alfred-core/core.cnf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = VN
ST = HoChiMinh
L = HoChiMinh
O = Alfred
OU = Core
CN = alfred-core

[req_ext]
subjectAltName = @alt_names
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[alt_names]
DNS.1 = alfred-core
DNS.2 = localhost
DNS.3 = core.alfred.local
IP.1 = 127.0.0.1
EOF

# Generate private key
openssl genrsa -out "$SCRIPT_DIR/alfred-core/core.key" 2048

# Generate CSR
openssl req -new \
    -key "$SCRIPT_DIR/alfred-core/core.key" \
    -out "$SCRIPT_DIR/alfred-core/core.csr" \
    -config "$SCRIPT_DIR/alfred-core/core.cnf"

# Sign with CA
openssl x509 -req \
    -in "$SCRIPT_DIR/alfred-core/core.csr" \
    -CA "$SCRIPT_DIR/ca/ca.crt" \
    -CAkey "$SCRIPT_DIR/ca/ca.key" \
    -CAcreateserial \
    -out "$SCRIPT_DIR/alfred-core/core.crt" \
    -days $VALIDITY_DAYS \
    -sha256 \
    -extensions req_ext \
    -extfile "$SCRIPT_DIR/alfred-core/core.cnf"

# Create PFX for .NET
openssl pkcs12 -export \
    -out "$SCRIPT_DIR/alfred-core/core.pfx" \
    -inkey "$SCRIPT_DIR/alfred-core/core.key" \
    -in "$SCRIPT_DIR/alfred-core/core.crt" \
    -certfile "$SCRIPT_DIR/ca/ca.crt" \
    -passout pass:

echo -e "${GREEN}✓ Alfred Core Server Certificate generated${NC}"

# ==============================================================================
# Summary
# ==============================================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Certificate Generation Complete!    ${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Generated files:${NC}"
echo -e "  CA Certificate:       $SCRIPT_DIR/ca/ca.crt"
echo -e "  CA Private Key:       $SCRIPT_DIR/ca/ca.key (KEEP SECRET!)"
echo -e ""
echo -e "  Gateway Client Cert:  $SCRIPT_DIR/gateway/gateway-client.pfx"
echo -e "  Identity Server Cert: $SCRIPT_DIR/alfred-identity/identity.pfx"
echo -e "  Core Server Cert:     $SCRIPT_DIR/alfred-core/core.pfx"

echo -e "\n${YELLOW}Certificate validity:${NC} $VALIDITY_DAYS days (≈10 years)"

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Mount certificates in Docker containers"
echo -e "  2. Configure backend services to use HTTPS with client certificate validation"
echo -e "  3. Configure Gateway YARP to use client certificate"

# Set proper permissions
chmod 600 "$SCRIPT_DIR/ca/ca.key"
chmod 600 "$SCRIPT_DIR/gateway/gateway-client.key"
chmod 600 "$SCRIPT_DIR/alfred-identity/identity.key"
chmod 600 "$SCRIPT_DIR/alfred-core/core.key"

echo -e "\n${GREEN}✓ Permissions set on private keys (600)${NC}"
