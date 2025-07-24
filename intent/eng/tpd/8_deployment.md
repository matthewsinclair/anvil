---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 8. Deployment

## Deployment Strategy

Anvil is designed for flexible deployment across various environments, from single-server setups to distributed cloud architectures. The application follows 12-factor app principles for maximum portability.

## Environment Configuration

### Environment Variables

```bash
# Core Configuration
PHX_HOST=anvil.example.com
PORT=4000
SECRET_KEY_BASE=64_character_secret
DATABASE_URL=postgres://user:pass@host:5432/anvil_prod

# Security
SESSION_ENCRYPTION_SALT=32_character_salt
SESSION_SIGNING_SALT=32_character_salt

# Email Configuration
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=sendgrid_api_key
FROM_EMAIL=noreply@anvil.example.com

# External Services
SENTRY_DSN=https://key@sentry.io/project
OTEL_EXPORTER_OTLP_ENDPOINT=https://otel.example.com

# Feature Flags
ENABLE_MAGIC_LINKS=true
ENABLE_API_KEYS=true
ENABLE_REGISTRATIONS=true
```

### Runtime Configuration

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable not set"

  config :anvil, Anvil.Repo,
    ssl: true,
    ssl_opts: [verify: :verify_none],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :anvil, AnvilWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST"), port: 443, scheme: "https"],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")
end
```

## Deployment Architectures

### Single Server (Small Scale)

```
┌─────────────────────────────────────────────────────────┐
│                    Single Server                        │
│                                                         │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────┐  │
│  │     Nginx      │  │   Phoenix App  │  │PostgreSQL │  │
│  │   (Reverse     │─▶│   (Port 4000)  │─▶│(Port 5432)│  │
│  │    Proxy)      │  │                │  │           │  │
│  └────────────────┘  └────────────────┘  └───────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Setup Script

```bash
#!/bin/bash
# deploy/single_server_setup.sh

# Install dependencies
sudo apt update
sudo apt install -y nginx postgresql-14 certbot python3-certbot-nginx

# Setup database
sudo -u postgres createuser -P anvil
sudo -u postgres createdb -O anvil anvil_prod

# Configure Nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/anvil
sudo ln -s /etc/nginx/sites-available/anvil /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Setup SSL
sudo certbot --nginx -d anvil.example.com

# Deploy application
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix ecto.migrate

# Create systemd service
sudo cp deploy/anvil.service /etc/systemd/system/
sudo systemctl enable anvil
sudo systemctl start anvil
```

### Multi-Server (Medium Scale)

```
            ┌─────────────────┐
            │  Load Balancer  │
            │   (HAProxy)     │
            └──────┬─────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
    ┌────▼───────┐      ┌────▼───────┐
    │ App Server │      │ App Server │
    │     #1     │      │     #2     │
    └─────┬──────┘      └─────┬──────┘
          │                   │
          └──────┬────────────┘
                 │
         ┌───────▼───────┐
         │  PostgreSQL   │
         │    Primary    │
         └───────┬───────┘
                 │
         ┌───────▼───────┐
         │  PostgreSQL   │
         │    Replica    │
         └───────────────┘
```

### Kubernetes (Large Scale)

#### Deployment Manifest

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: anvil-app
  namespace: anvil
spec:
  replicas: 3
  selector:
    matchLabels:
      app: anvil
  template:
    metadata:
      labels:
        app: anvil
    spec:
      containers:
      - name: anvil
        image: anvil/app:latest
        ports:
        - containerPort: 4000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: anvil-secrets
              key: database_url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: anvil-secrets
              key: secret_key_base
        livenessProbe:
          httpGet:
            path: /health
            port: 4000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 4000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## Container Strategy

### Dockerfile

```dockerfile
# Dockerfile
# Build stage
FROM elixir:1.15-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git python3 nodejs npm

# Set build environment
ENV MIX_ENV=prod

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy deps files
COPY mix.exs mix.lock ./
COPY config config

# Install dependencies
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Copy application files
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile application
RUN mix compile

# Build release
COPY rel rel
RUN mix release

# Runtime stage
FROM alpine:3.18 AS runtime

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Create non-root user
RUN adduser -D -h /app anvil

# Copy release from build stage
COPY --from=build --chown=anvil:anvil /app/_build/prod/rel/anvil ./

USER anvil

EXPOSE 4000

CMD ["bin/anvil", "start"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: anvil
      POSTGRES_PASSWORD: anvil_pass
      POSTGRES_DB: anvil_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  app:
    build: .
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgres://anvil:anvil_pass@postgres:5432/anvil_dev
      SECRET_KEY_BASE: dev_secret_key_base_64_characters_long_for_development
      PHX_HOST: localhost
    ports:
      - "4000:4000"
    volumes:
      - .:/app
      - /app/_build
      - /app/deps

volumes:
  postgres_data:
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.15'
        otp-version: '26'
    
    - name: Run tests
      env:
        DATABASE_URL: postgres://postgres:postgres@localhost/anvil_test
      run: |
        mix deps.get
        mix test
    
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build and push Docker image
      env:
        DOCKER_REGISTRY: ${{ secrets.DOCKER_REGISTRY }}
      run: |
        docker build -t $DOCKER_REGISTRY/anvil:$GITHUB_SHA .
        docker push $DOCKER_REGISTRY/anvil:$GITHUB_SHA
    
    - name: Deploy to production
      run: |
        # Deploy script (kubectl, fly.io, etc.)
        ./deploy/production.sh $GITHUB_SHA
```

## Database Management

### Migrations

```bash
# Run migrations on deployment
bin/anvil eval "Anvil.Release.migrate()"

# Rollback if needed
bin/anvil eval "Anvil.Release.rollback(Anvil.Repo, 1)"
```

### Backup Strategy

```bash
#!/bin/bash
# deploy/backup.sh

# Daily backup with retention
BACKUP_NAME="anvil_$(date +%Y%m%d_%H%M%S).sql"
DATABASE_URL="postgres://user:pass@host/anvil_prod"

# Create backup
pg_dump $DATABASE_URL | gzip > /backups/$BACKUP_NAME.gz

# Upload to S3
aws s3 cp /backups/$BACKUP_NAME.gz s3://anvil-backups/daily/

# Clean up old backups (keep 30 days)
find /backups -name "*.gz" -mtime +30 -delete
```

## Monitoring

### Health Checks

```elixir
# lib/anvil_web/controllers/health_controller.ex
defmodule AnvilWeb.HealthController do
  use AnvilWeb, :controller

  def health(conn, _params) do
    checks = %{
      app: :ok,
      database: check_database(),
      cache: check_cache()
    }
    
    status = if Enum.all?(checks, fn {_, v} -> v == :ok end), do: 200, else: 503
    
    conn
    |> put_status(status)
    |> json(checks)
  end
  
  defp check_database do
    case Ecto.Adapters.SQL.query(Anvil.Repo, "SELECT 1", []) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end
end
```

### Metrics Collection

```elixir
# config/runtime.exs
config :opentelemetry,
  resource: [
    service: [
      name: "anvil",
      namespace: "production"
    ]
  ],
  processors: [
    otel_batch_processor: %{
      exporter: {
        opentelemetry_exporter,
        %{
          endpoints: [{System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT"), []}]
        }
      }
    }
  ]
```

## Operations Runbook

### Common Tasks

#### Rolling Restart

```bash
# Kubernetes
kubectl rollout restart deployment/anvil-app -n anvil

# Docker Swarm
docker service update --force anvil_app
```

#### Database Console

```bash
# Production console
kubectl exec -it deployment/anvil-app -- bin/anvil remote

# Direct database access
kubectl port-forward service/postgres 5432:5432
psql $DATABASE_URL
```

#### Log Access

```bash
# Tail application logs
kubectl logs -f deployment/anvil-app -n anvil

# Search logs
kubectl logs deployment/anvil-app -n anvil | grep ERROR
```

### Emergency Procedures

#### Rollback Deployment

```bash
# Kubernetes
kubectl rollout undo deployment/anvil-app -n anvil

# Docker
docker service update anvil_app --image anvil/app:previous_tag
```

#### Database Recovery

```bash
# Restore from backup
pg_restore -d $DATABASE_URL /backups/anvil_20250724.sql

# Point-in-time recovery
pg_basebackup -h primary -D /recovery
```
