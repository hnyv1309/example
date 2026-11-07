#!/usr/bin/env bash
# Switch from Cloudflare WARP to Proton VPN
# Usage: ./run.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

echo "==> Disconnecting WARP..."
warp-cli disconnect 2>/dev/null || true
sleep 1

echo "==> Stopping systemd-resolved to flush WARP DNS state..."
systemctl stop systemd-resolved
sleep 1

echo "==> Removing any leftover WARP resolv.conf..."
rm -f /etc/resolv.conf

echo "==> Starting systemd-resolved fresh..."
systemctl start systemd-resolved
sleep 1

echo "==> Ensuring resolv.conf points to stub resolver..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "==> Flushing resolved caches..."
resolvectl flush-caches 2>/dev/null || true

echo "==> Verifying DNS..."
if host www.google.com > /dev/null 2>&1; then
    echo "    ✅ DNS is working"
else
    echo "    ❌ DNS still broken, falling back to 1.1.1.1"
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

echo "==> Launching Proton VPN..."
SUDO_USER=${SUDO_USER:-leo}
sudo -u "$SUDO_USER" nohup protonvpn-app > /dev/null 2>&1 &
echo "Done."
