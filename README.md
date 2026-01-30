# Alfred Infrastructure

Docker-based infrastructure for the complete Alfred project ecosystem.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Reverse Proxy)                     │
│              SSL Termination, Rate Limiting                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Alfred Gateway (YARP)                      │
│          API Gateway, Routing, Authentication                │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
┌───────────────────────┐   ┌───────────────────────┐
│  Alfred Identity      │   │   Future Services     │
│  Authentication       │   │   (Microservices)     │
└───────────────────────┘   └───────────────────────┘
        │         │
        ▼         ▼
┌──────────┐  ┌──────────┐
│PostgreSQL│  │  Redis   │
│ Database │  │  Cache   │
└──────────┘  └──────────┘
```

## 📦 Services

### Core Services

| Service | Port | Description |
|---------|------|-------------|
| **Alfred Gateway** | 8000 | API Gateway (YARP) - Routes and authenticates requests |
| **Alfred Identity** | 5001 | Identity & Authentication service |
| **PostgreSQL** | 5432 | Primary database |
| **Redis** | 6379 | Caching and session management |
| **Nginx** | 80/443 | Reverse proxy (Production only) |

### Management Tools (Development)

| Tool | Port | Description |
|------|------|-------------|
| **pgAdmin** | 5050 | PostgreSQL management interface |
| **Redis Commander** | 8081 | Redis management interface |

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Make (optional, for convenience commands)

### Development Environment

1. **Clone and setup**
   ```bash
   cd alfred-infra
   make init-env
   ```

2. **Update `.env` file with your configuration**
   ```bash
   vim .env
   ```

3. **Start all services**
   ```bash
   make dev
   ```

4. **Start management tools (optional)**
   ```bash
   make dev-tools
   ```

5. **Run database migrations**
   ```bash
   make migrate
   ```

6. **Seed initial data**
   ```bash
   make seed
   ```

### Access Services

- **API Gateway**: http://localhost:8000
- **Identity API**: http://localhost:5001
- **pgAdmin**: http://localhost:5050 (email: admin@alfred.com, password: admin123)
- **Redis Commander**: http://localhost:8081

## 🏭 Production Deployment

### Production with mTLS (Recommended)

The production environment uses mutual TLS (mTLS) for secure service-to-service authentication:

#### Quick Deploy

```bash
# One command to deploy everything with mTLS
cd alfred-infra
make prod-deploy

# Check deployment status
make prod-health

# View logs
make prod-logs
```

#### mTLS Architecture

**Service Communication:**
- **Gateway → Backend Services**: Gateway presents client certificate on all HTTPS requests
- **Backend → Gateway**: Backend services validate certificates signed by internal CA
- **Health Checks**: Use separate HTTP endpoints (8100/8200) without certificate requirements
- **Application Traffic**: Uses HTTPS endpoints (8101/8201) with full mTLS protection

**Ports:**

| Service  | HTTP (Health) | HTTPS (mTLS) | External |
|----------|---------------|--------------|----------|
| Gateway  | -             | -            | 8000     |
| Identity | 8100          | 8101         | -        |
| Core     | 8200          | 8201         | -        |

**Certificate Details:**
- **Validity**: 10 years (no frequent rotation)
- **Location**: `./certificates/` directory
- **Components**: CA certificate, server certificates (Identity, Core), client certificate (Gateway)
- **Auto-generation**: Certificates are generated automatically by `make prod-deploy`

#### Manual Certificate Management

```bash
# Regenerate certificates (if needed)
make mtls-certs

# Test mTLS configuration
make mtls-test
```

#### Testing Production Deployment

```bash
# Test Gateway health
curl http://localhost:8000/health

# Test backend health through Gateway (uses mTLS internally)
curl http://localhost:8000/health/identity
curl http://localhost:8000/health/core

# Test application endpoints (protected by mTLS)
curl http://localhost:8000/applications
curl http://localhost:8000/users
```

#### Environment Configuration

The `.env.prod` file controls mTLS settings:

```bash
# mTLS is enabled by default in production
MTLS_ENABLED=true

# Database credentials
POSTGRES_USER=alfred
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=alfred_db

# Frontend URL for CORS
FRONTEND_URL=https://yourdomain.com
```

### Production without mTLS (Not Recommended)

To disable mTLS in production (not recommended for security):

```bash
# Edit .env.prod
echo "MTLS_ENABLED=false" > .env.prod

# Deploy
make prod-up
```

## 📋 Available Commands

Run `make help` to see all available commands for managing the infrastructure.

## 📝 License

Copyright © 2026 Alfred Project