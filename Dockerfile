# ============================================
# AIOMetadata Docker Build
# Multi-stage build with HEALTHCHECK
# Source: https://github.com/cedya77/aiometadata
# ============================================

ARG VERSION=latest

# ============================================
# Stage 1: Clone and Build
# ============================================
FROM node:20-alpine AS builder

ARG VERSION

WORKDIR /app

# Install git for cloning
RUN apk add --no-cache git

# Clone specific version from source repository
RUN if [ "$VERSION" = "latest" ]; then \
      git clone --depth 1 https://github.com/cedya77/aiometadata.git . ; \
    else \
      git clone --depth 1 --branch "v${VERSION}" https://github.com/cedya77/aiometadata.git . ; \
    fi

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Build frontend (Vite)
RUN npm run build

# Build backend (TypeScript)
RUN npm run build:backend

# ============================================
# Stage 2: Production Dependencies
# ============================================
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files from builder
COPY --from=builder /app/package*.json ./

# Install production dependencies only
# This layer is cached and reused across versions with same deps
RUN npm ci --production --ignore-scripts && \
    npm cache clean --force

# ============================================
# Stage 3: Final Production Image
# ============================================
FROM node:20-alpine AS runner

# Build arguments for OCI labels
ARG VERSION=latest
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL=https://github.com/cedya77/aiometadata

# OCI Image Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="AIOMetadata" \
      org.opencontainers.image.description="The Ultimate Stremio Metadata Addon - Docker image with HEALTHCHECK" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="${VCS_URL}" \
      org.opencontainers.image.url="https://github.com/JigSawFr/aiometadata-docker" \
      org.opencontainers.image.vendor="JigSawFr" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="docker.io/library/node:20-alpine"

WORKDIR /app

# Install runtime dependencies
# - ca-certificates: SSL/TLS verification
# - wget: for healthcheck
RUN apk add --no-cache ca-certificates wget

# Copy production dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy package.json for version info
COPY --from=builder /app/package*.json ./

# Copy built application from builder stage
COPY --from=builder /app/addon ./addon
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose default port
EXPOSE 1337

# Environment defaults
ENV NODE_ENV=production \
    PORT=1337

# Health check configuration
# - interval: Check every 30 seconds
# - timeout: Fail if no response in 10 seconds  
# - start-period: Wait 60 seconds for app to start (initial warmup)
# - retries: Mark unhealthy after 3 consecutive failures
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:1337/api/cache/health || exit 1

# Start the application
ENTRYPOINT ["node", "dist/server.js"]
