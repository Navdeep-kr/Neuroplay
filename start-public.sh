#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "==============================================================================="
echo "                     NEUROPLAY PRODUCTION SERVER"
echo "==============================================================================="
echo ""

# Try detecting local IP
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' || echo "")

echo "[*] Server is binding to all network interfaces (0.0.0.0:3000)"
echo ""
echo "    Local PC Access:     http://localhost:3000"
if [ -n "$LOCAL_IP" ]; then
    echo "    LAN / Mobile Access: http://${LOCAL_IP}:3000"
    echo "    Direct Flutter App:  http://${LOCAL_IP}:3000/app/"
fi
echo ""
echo "[*] Press Ctrl+C at any time to stop the server."
echo "==============================================================================="
echo ""

cd "$DIR/website"
pnpm start
