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

See full documentation in this README for production setup with SSL, Nginx, and security best practices.

## 📋 Available Commands

Run `make help` to see all available commands for managing the infrastructure.

## 📝 License

Copyright © 2026 Alfred Project