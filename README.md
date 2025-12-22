# AIOMetadata Docker

[![Latest Version](https://img.shields.io/github/v/release/JigSawFr/aiometadata-docker?label=version&style=flat-square)](https://github.com/JigSawFr/aiometadata-docker/releases)
[![Docker Pulls](https://img.shields.io/badge/ghcr.io-jigsawfr%2Faiometadata--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/jigsawfr/aiometadata-docker)
[![Build Status](https://img.shields.io/github/actions/workflow/status/JigSawFr/aiometadata-docker/build-new-releases.yml?style=flat-square&label=build)](https://github.com/JigSawFr/aiometadata-docker/actions/workflows/build-new-releases.yml)
[![License](https://img.shields.io/github/license/JigSawFr/aiometadata-docker?style=flat-square)](LICENSE)

> 🐳 Docker images for [AIOMetadata](https://github.com/cedya77/aiometadata) - The Ultimate Stremio Metadata Addon

This repository automatically builds and publishes versioned Docker images from the official [cedya77/aiometadata](https://github.com/cedya77/aiometadata) releases.

## ✨ Features

- 🔄 **Auto-sync** - Automatically builds new releases every 6 hours
- 🏷️ **Versioned tags** - Full semver support (`1.15.0`, `1.15`, `1`, `latest`, `beta`)
- 🏗️ **Multi-arch** - Supports `linux/amd64` and `linux/arm64`
- 🩺 **Healthcheck** - Built-in Docker HEALTHCHECK for orchestrators
- 🔐 **Signed images** - All images signed with Cosign (keyless/OIDC)
- 📋 **SBOM** - Software Bill of Materials attached to each image
- 🗜️ **Optimized** - Zstd compression for smaller image size

## 🚀 Quick Start

### Docker Run

```bash
docker run -d \
  --name aiometadata \
  -p 1337:1337 \
  -e REDIS_URL=redis://your-redis:6379 \
  -e HOST_NAME=http://localhost:1337 \
  -e TMDB_API=your_tmdb_api_key \
  -e DATABASE_URL=file:./addon/data/addon.db \
  ghcr.io/jigsawfr/aiometadata-docker:latest
```

### Docker Compose (Recommended)

1. Download the docker-compose.yml:
```bash
curl -O https://raw.githubusercontent.com/JigSawFr/aiometadata-docker/main/docker-compose.yml
```

2. Create a `.env` file:
```bash
# Required
HOST_NAME=https://your-domain.com
TMDB_API=your_tmdb_api_key

# Optional
ADMIN_KEY=your_admin_key
FANART_API=your_fanart_api_key
RPDB_API_KEY=your_rpdb_api_key
```

3. Start the stack:
```bash
docker compose up -d
```

## 📦 Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable release |
| `beta` | Latest pre-release/beta |
| `1.15.0` | Specific version |
| `1.15` | Latest patch for v1.15.x |
| `1` | Latest minor/patch for v1.x.x |

### Pull Commands

```bash
# Latest stable
docker pull ghcr.io/jigsawfr/aiometadata-docker:latest

# Specific version
docker pull ghcr.io/jigsawfr/aiometadata-docker:1.15.0

# Beta channel
docker pull ghcr.io/jigsawfr/aiometadata-docker:beta
```

## 🔧 Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379` |
| `HOST_NAME` | Your public domain | `https://your-domain.com` |
| `TMDB_API` | TMDB API key ([Get one](https://www.themoviedb.org/settings/api)) | `abc123...` |
| `DATABASE_URL` | SQLite or PostgreSQL URL | `file:./addon/data/addon.db` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `1337` |
| `ADMIN_KEY` | Dashboard admin key | - |
| `ADDON_PASSWORD` | Addon protection password | - |
| `FANART_API` | Fanart.tv API key | - |
| `RPDB_API_KEY` | RatingPosterDB API key | - |
| `OMDB_API` | OMDB API key | - |
| `META_TTL` | Metadata cache TTL (seconds) | `604800` (7 days) |
| `CATALOG_TTL` | Catalog cache TTL (seconds) | `86400` (1 day) |
| `LOG_LEVEL` | Logging level | `info` |

## 🔐 Verify Image Signature

All images are signed with [Cosign](https://github.com/sigstore/cosign). Verify with:

```bash
cosign verify ghcr.io/jigsawfr/aiometadata-docker:latest \
  --certificate-identity-regexp=".*" \
  --certificate-oidc-issuer-regexp=".*"
```

## 🩺 Health Check

The container includes a built-in health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:1337/api/cache/health || exit 1
```

Monitor health status:
```bash
docker inspect --format='{{.State.Health.Status}}' aiometadata
```

## 📊 Monitoring

Access the dashboard at `http://your-host:1337/dashboard` (requires `ADMIN_KEY` if set).

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Configuration UI |
| `/dashboard` | Admin dashboard |
| `/api/cache/health` | Health check endpoint |
| `/stremio/:uuid/manifest.json` | Stremio manifest |

## 🔄 Updates

Images are automatically built when:
- A new release is published on [cedya77/aiometadata](https://github.com/cedya77/aiometadata)
- The Node.js Alpine base image is updated (via Renovate)

### Manual Update

```bash
docker compose pull
docker compose up -d
```

## 📁 Volumes

| Path | Description |
|------|-------------|
| `/app/addon/data` | SQLite database and user data |

## 🌐 Reverse Proxy

### Traefik

Uncomment the Traefik labels in `docker-compose.yml`:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.aiometadata.rule=Host(`aiometadata.yourdomain.com`)"
  - "traefik.http.routers.aiometadata.entrypoints=websecure"
  - "traefik.http.routers.aiometadata.tls.certresolver=letsencrypt"
  - "traefik.http.services.aiometadata.loadbalancer.server.port=1337"
```

### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name aiometadata.yourdomain.com;

    location / {
        proxy_pass http://localhost:1337;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🤝 Contributing

Issues and PRs are welcome! For upstream addon issues, please report to [cedya77/aiometadata](https://github.com/cedya77/aiometadata/issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Upstream Project**: [cedya77/aiometadata](https://github.com/cedya77/aiometadata)  
**Last Check**: <!-- LAST_CHECK_PLACEHOLDER -->
