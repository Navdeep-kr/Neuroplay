# 🚀 NEUROPLAY — Public Deployment & Production Guide

This guide provides everything needed to run, deploy, and share **NEUROPLAY** with the public across local networks, custom domains, cloud providers, and containerized clusters.

---

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Instant Local & LAN Testing](#instant-local--lan-testing)
3. [Zero-Cost Free Cloud Deployment (Vercel)](#zero-cost-free-cloud-deployment-vercel)
4. [Container Deployment (Docker & Docker Compose)](#container-deployment-docker--docker-compose)
5. [Instant Public HTTPS Tunnel (Cloudflare Tunnels)](#instant-public-https-tunnel-cloudflare-tunnels)
6. [Production Linux VPS Deployment (Nginx + SSL)](#production-linux-vps-deployment-nginx--ssl)
7. [Production Optimization Checklist](#production-optimization-checklist)

---

## 1. Architecture Overview

NEUROPLAY is engineered as a unified hybrid architecture:
- **Frontend / Marketing & Portal**: Next.js 16 (App Router + Tailwind CSS 4) serving landing pages, science documentation, feature tours, and dynamic routing.
- **Cognitive Engine & Games (`/app/`)**: High-performance Flutter 3.38+ Web application compiled to WebAssembly with local CanvasKit (`canvaskit.wasm`).
- **Zero-External CDN Bottleneck**: All 12 games, sounds, fonts, and WebAssembly binaries are bundled locally in `website/public/app/`, eliminating CDN throttling and firewall/adblocker blocks.

```
                    ┌────────────────────────────────────────┐
                    │               User / Browser           │
                    └───────────────────┬────────────────────┘
                                        │
                         HTTP / HTTPS (Port 3000)
                                        │
                    ┌───────────────────▼────────────────────┐
                    │            Next.js Server              │
                    ├────────────────────┬───────────────────┤
                    │   Marketing Pages  │    /app Route     │
                    │   (/, /games, etc.)│ (Flutter WASM App)│
                    └────────────────────┴─────────┬─────────┘
                                                   │
                                     ┌─────────────▼────────────┐
                                     │   12 Cognitive Workouts  │
                                     │  • Echo Sequence         │
                                     │  • Constellation Recall  │
                                     │  • Trailblazer           │
                                     │  • Prism Shift           │
                                     │  • Tracker Horizon       │
                                     │  • Flanker Strike        │
                                     │  • Scale Balance         │
                                     │  • Flow Math             │
                                     │  • Origami Unfold        │
                                     │  • Tower of Chronos      │
                                     │  • Semantic Bridge       │
                                     │  • Word Rapids           │
                                     └──────────────────────────┘
```

---

## 2. Instant Local & LAN Testing

NEUROPLAY binds to `0.0.0.0:3000`, making it accessible to any phone, tablet, or computer on the same Wi-Fi / Local Area Network.

### Windows (1-Click)
Double-click `start-public.bat` or run:
```bat
start-public.bat
```
*The script automatically detects your machine's Wi-Fi / Ethernet IPv4 address, opens your default browser, and displays the direct mobile URL (e.g. `http://192.168.1.50:3000`).*

### macOS / Linux
Run:
```bash
chmod +x start-public.sh
./start-public.sh
```

---

## 3. Zero-Cost Free Cloud Deployment (Vercel)

Deploying NEUROPLAY to Vercel takes under 2 minutes:

1. Push your repository to **GitHub** or **GitLab**.
2. Go to [vercel.com](https://vercel.com) and click **"Add New Project"**.
3. Import your repository.
4. Set the **Root Directory** to `website`.
5. Vercel automatically detects Next.js:
   - **Framework Preset**: Next.js
   - **Build Command**: `pnpm build`
   - **Output Directory**: `.next`
6. Click **Deploy**.

> [!NOTE]
> The included [website/vercel.json](file:///d:/Neuroplay/website/vercel.json) automatically sets up URL rewriting for `/app/` and enables 1-year immutable caching for `canvaskit.wasm` and game asset files.

---

## 4. Container Deployment (Docker & Docker Compose)

NEUROPLAY includes a multi-stage production [Dockerfile](file:///d:/Neuroplay/Dockerfile) and [docker-compose.yml](file:///d:/Neuroplay/docker-compose.yml) suitable for any cloud container service (AWS ECS, Google Cloud Run, DigitalOcean App Platform, Fly.io, Railway, or Render).

### Running with Docker Compose
```bash
docker compose up -d --build
```
Access the application at `http://localhost:3000` or `http://<server-ip>:3000`.

### Standalone Docker Commands
```bash
# Build production image
docker build -t neuroplay:latest .

# Run container binding to port 80 or 3000
docker run -d -p 80:3000 --name neuroplay neuroplay:latest
```

---

## 5. Instant Public HTTPS Tunnel (Cloudflare Tunnels)

To share your running local instance with anyone in the world instantly over a secure HTTPS URL without opening router ports or buying a domain:

1. Download [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/):
   ```powershell
   # Windows (winget)
   winget install Cloudflare.cloudflared
   ```
2. Start the tunnel to your local server:
   ```bash
   cloudflared tunnel --url http://localhost:3000
   ```
3. Cloudflare will print a live public HTTPS URL (e.g., `https://random-words.trycloudflare.com`). Anyone can open this link from anywhere in the world on desktop or mobile.

---

## 6. Production Linux VPS Deployment (Nginx + SSL)

For hosting on an Ubuntu/Debian server (DigitalOcean Droplet, Linode, AWS EC2, Hetzner):

### Step 1: Install Node.js, pnpm, & PM2
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs nginx certbot python3-certbot-nginx
sudo npm install -g pnpm pm2
```

### Step 2: Clone and Build
```bash
git clone https://github.com/your-username/neuroplay.git /var/www/neuroplay
cd /var/www/neuroplay/website
pnpm install --frozen-lockfile
pnpm build
```

### Step 3: Run with PM2 Process Manager
```bash
pm2 start pnpm --name "neuroplay" -- start
pm2 save
pm2 startup
```

### Step 4: Configure Nginx Reverse Proxy
Create `/etc/nginx/sites-available/neuroplay`:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Gzip Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site and reload Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/neuroplay /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 5: Provision Free SSL with Let's Encrypt
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## 7. Production Optimization Checklist

- [x] **Local CanvasKit WASM**: Flutter boots from local static wasm without Google gstatic network latency.
- [x] **0.0.0.0 Network Binding**: Accessible from mobile devices, LAN, and public proxies.
- [x] **Double-Pop Bug Eliminated**: All 12 games smoothly transition into active gameplay immediately.
- [x] **Dialog Viewport Constraints**: Tutorial modals fit comfortably on desktop and mobile viewports.
- [x] **Long-Term Cache Headers**: 1-year immutable caching for wasm, web fonts, and audio assets.
- [x] **Clean SPA Rewrites**: Deep links to `/app` and `/app/` resolve seamlessly to Flutter's entrypoint.
