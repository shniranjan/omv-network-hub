#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "=== OMV Network Hub — Health Check ==="
echo

echo "--- Containers ---"
docker compose ps 2>/dev/null || echo "  docker compose not available"

echo
echo "--- DNS (Pi-hole) ---"
if nslookup -timeout=5 google.com 127.0.0.1 -port=53 >/dev/null 2>&1; then
    echo "  ✅ DNS resolving via Pi-hole"
else
    echo "  ❌ DNS not resolving"
fi

echo
echo "--- Proxy (tinyproxy) ---"
if curl -s --max-time 5 -x http://127.0.0.1:8888 http://example.com >/dev/null 2>&1; then
    echo "  ✅ Forward proxy responding on :8888"
else
    echo "  ❌ Proxy not responding on :8888"
fi

echo
echo "--- SSH Tunnel ---"
docker compose logs tunnel --tail 3 2>/dev/null || echo "  (check container logs manually)"

echo
echo "=== Done ==="
