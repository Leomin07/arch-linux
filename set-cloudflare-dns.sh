#!/bin/bash
# Script: Đặt DNS là 1.1.1.1 và 1.0.0.1 trên Arch Linux

set -euo pipefail

echo "🔧 Kích hoạt systemd-resolved..."
sudo systemctl enable --now systemd-resolved

echo "🔗 Liên kết lại /etc/resolv.conf..."
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "📝 Cấu hình DNS Cloudflare vào /etc/systemd/resolved.conf..."
sudo sed -i '/^#*DNS=/d' /etc/systemd/resolved.conf
sudo sed -i '/^#*FallbackDNS=/d' /etc/systemd/resolved.conf

sudo tee -a /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.8 8.8.4.4
EOF

echo "🔁 Khởi động lại systemd-resolved..."
sudo systemctl restart systemd-resolved

echo "✅ Đã đổi DNS thành công:"
resolvectl status | grep "DNS Servers"
