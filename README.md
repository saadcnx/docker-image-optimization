# 🐳 Docker Image Optimization — From 1.5GB to Under 100MB

A hands-on deep dive into production-grade Docker image optimization techniques. This project demonstrates how to reduce container image sizes by **90%+** using multi-stage builds, minimal base images, layer optimization, and security hardening — without sacrificing functionality.

---

## 📊 Results at a Glance

| Image Version | Size | Layers | Runs as Root |
|---|---|---|---|
| Unoptimized (`node:18` + extras) | ~1.5 GB | 15+ | ✅ Yes |
| Multi-stage build | ~300 MB | 12 | ✅ Yes |
| Alpine-based | ~180 MB | 10 | ❌ No |
| Layer-optimized Alpine | ~130 MB | 8 | ❌ No |
| Final production image | ~50–100 MB | 7 | ❌ No |

> **90%+ size reduction** — faster pulls, cheaper storage, smaller attack surface.

---

## 🗂️ Project Structure

```
.
├── sample-app/
│   ├── server.js                  # Node.js Express application
│   ├── package.json
│   ├── .dockerignore              # Build context exclusions
│   ├── Dockerfile.unoptimized     # Baseline image (no optimizations)
│   ├── Dockerfile.multistage      # Multi-stage build
│   ├── Dockerfile.alpine          # Alpine Linux base
│   ├── Dockerfile.optimized       # Layer-optimized version
│   ├── Dockerfile.production      # Production-ready image
│   ├── Dockerfile.minimal         # Minimal Alpine + Node
│   └── Dockerfile.ultimate        # BuildKit + distroless
├── docker-compose.prod.yml        # Production deployment config
└── compare_images.sh              # Automated size comparison script
```

---

## 🔧 Techniques Covered

### 1. Multi-Stage Builds
Separates the **build environment** from the **runtime environment** — keeping build tools, dev dependencies, and compilation artifacts out of the final image.

```dockerfile
FROM node:18 AS builder
RUN npm ci --only=production

FROM node:18-slim AS production
COPY --from=builder /app/node_modules ./node_modules
```

### 2. Minimal Base Images (Alpine Linux)
Swapping `node:18` (~950MB) for `node:18-alpine` (~50MB) is one of the single biggest wins. Alpine's musl libc + busybox approach strips everything non-essential.

```dockerfile
FROM node:18-alpine AS production
RUN apk add --no-cache curl
```

### 3. Layer Optimization
Combining `RUN` commands reduces the number of intermediate layers and prevents bloating from temporary files left in earlier layers.

```dockerfile
# ❌ Creates 3 layers, temp files persist
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ Single layer, clean state
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
```

### 4. `.dockerignore` — Trimming the Build Context
Excluding `node_modules`, logs, test files, and IDE configs reduces the build context sent to the Docker daemon — speeding up builds and preventing accidental secrets from entering images.

```dockerignore
node_modules/
.env
.env.local
tests/
docs/
*.log
.git
.DS_Store
```

### 5. Non-Root User (Security Hardening)
Production images run as a dedicated non-root user, reducing the blast radius of any container escape.

```dockerfile
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001
USER appuser
```

### 6. Health Checks
Built-in health checks enable orchestrators (Docker Swarm, Kubernetes) to detect and replace unhealthy containers automatically.

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

### 7. BuildKit Cache Mounts *(Advanced)*
BuildKit's `--mount=type=cache` keeps npm/pip caches between builds, dramatically speeding up rebuilds without bloating the image.

```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production
```

---

## 🚀 Quick Start

**Prerequisites:** Docker Engine 20.10+

```bash
# Clone the repo
git clone https://github.com/saadcnx/docker-image-optimization.git
cd docker-image-optimization/sample-app

# Build the final production image
docker build -f Dockerfile.minimal -t sample-app:minimal .

# Run it
docker run -d -p 3000:3000 sample-app:minimal

# Test it
curl http://localhost:3000
curl http://localhost:3000/health
```

**Compare all image sizes:**
```bash
chmod +x compare_images.sh
./compare_images.sh
```

**Production deployment (with resource limits):**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

---

## 📚 Key Takeaways

- **Copy `package.json` before source code** — this preserves the npm install cache layer; source changes won't invalidate it.
- **`npm ci` over `npm install`** — deterministic, faster, and respects `package-lock.json`.
- **`npm cache clean --force`** — always clean caches inside the same `RUN` layer they're created in.
- **Distroless images** remove even the shell, `apk`, and OS package manager — ideal for high-security environments.
- **`tini` as PID 1** — ensures proper signal handling and zombie process reaping in containers.

---

## 🛡️ Security Checklist

- [x] Non-root user in all production images
- [x] No package managers (`apt`, `apk`) in final layers where possible
- [x] `no-new-privileges` security option in Compose
- [x] Read-only filesystem with `tmpfs` for writable paths
- [x] Resource limits (CPU + memory) defined
- [x] Health checks configured

---

## 🧰 Tech Stack

- **Runtime:** Node.js 18, Express
- **Base Images:** `node:18`, `node:18-slim`, `node:18-alpine`, `alpine:3.18`, `gcr.io/distroless/nodejs18`
- **Tools:** Docker BuildKit, Docker Compose, tini

---

## 📖 Further Reading

- [Docker Official — Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Alpine Linux Package Index](https://pkgs.alpinelinux.org/)
- [Google Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Docker BuildKit documentation](https://docs.docker.com/build/buildkit/)
