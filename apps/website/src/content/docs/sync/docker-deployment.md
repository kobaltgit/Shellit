---
title: Docker Compose Deployment
description: Deploying your own private Shellit E2EE synchronization server using Docker Compose.
---

Shellit provides a lightweight, prebuilt Docker image for hosting your private synchronization relay.

## 1. Prepare Docker Compose Configuration

Create a directory (e.g., `/opt/shellit-sync`) and create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  shellit-sync:
    image: ghcr.io/shellit/sync-server:latest
    container_name: shellit-sync
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - PORT=8080
      - BIND_ADDRESS=0.0.0.0
      - DATA_PATH=/data/shellit-sync.db
      - REGISTRATION_TOKEN=your-random-secure-token-here
      - MAX_PAYLOAD_MB=50
```

## 2. Launch Container

Start the service in detached mode:

```bash
docker compose up -d
```

Verify the service logs to ensure SQLite initialized properly:

```bash
docker compose logs -f
```

## 3. Reverse Proxy & SSL (Recommended)

For production deployments, place the server behind Nginx, Caddy, or Traefik with TLS enabled:

```nginx
server {
    server_name sync.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 4. Connect from Shellit Client

1. Open Shellit on your desktop or mobile device.
2. Navigate to **Settings $\rightarrow$ Synchronization**.
3. Enter your server endpoint: `https://sync.yourdomain.com` (or `http://192.168.1.100:8080` for LAN-only setups).
4. Provide the `REGISTRATION_TOKEN` configured above.
5. Click **"Connect & Sync"** — end-to-end encrypted synchronization is now active!
