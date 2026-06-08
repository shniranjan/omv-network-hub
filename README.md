# OMV Network Hub

> DNS (Pi-hole) + forward proxy (tinyproxy) + SSH tunnel (autossh) — all in one Docker Compose stack. Runs on OpenMediaVault or any Docker host.

## Architecture

```
                    OMV DOCKER
                    ┌─────────────────────────────────────┐
  LAN Devices ────→ │ pihole        (DNS :53)             │
                    │ tinyproxy     (forward proxy :8888)  │→ Internet
                    │ ssh-tunnel    (autossh → VPS → HA)   │→ VPS
                    └─────────────────────────────────────┘
```

## Quick Start

```bash
git clone https://github.com/shniranjan/omv-network-hub.git
cd omv-network-hub

# Configure
cp .env.example .env
nano .env   # set PIHOLE_WEBPASSWORD, VPS_HOST, VPS_USER, etc.

# Generate SSH key for tunnel
ssh-keygen -t ed25519 -f config/ssh/id_rsa -N ""
ssh-copy-id -i config/ssh/id_rsa.pub ${VPS_USER}@${VPS_HOST}

# Start
docker compose up -d
```

## Router Setup

In your router's DHCP settings, set **DNS server** to this host's IP (the OMV IP).
All devices will use Pi-hole for DNS filtering and ad blocking.

## Proxy Setup

Configure devices to use the forward proxy (opt-in):

- **HTTP Proxy:** `OMV_IP:8888`
- Or at OS level: Settings → Network → Proxy → Manual → `OMV_IP:8888`

## SSH Tunnel (HA Remote Access)

The tunnel container maintains an encrypted connection to your VPS. On the VPS nginx:

```nginx
location / {
    proxy_pass http://localhost:38123;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Replace `localhost:38123` with the `TUNNEL_REMOTE_PORT` from your `.env`.

## Verification

```bash
# Health check
bash scripts/healthcheck.sh

# DNS working?
nslookup google.com OMV_IP

# Proxy working?
curl -x http://OMV_IP:8888 http://example.com

# Tunnel alive?
ssh user@vps "curl -s localhost:38123" | head -5
```

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | All 3 services (pihole, tinyproxy, tunnel) |
| `.env` | Your config — copy from `.env.example` |
| `config/tinyproxy/tinyproxy.conf` | Forward proxy rules (LAN only) |
| `config/ssh/ssh_config` | autossh settings |
| `config/ssh/id_rsa` | SSH key for VPS (gitignored, generate locally) |
| `scripts/healthcheck.sh` | One-command health check |

## OPNsense Integration

If you later add OPNsense as your firewall/router:
- Point OPNsense DHCP DNS to this host (Pi-hole)
- Disable Pi-hole's DHCP (let OPNsense handle it)
- Tunnel and proxy stay on OMV, OPNsense handles routing/NAT/firewall
