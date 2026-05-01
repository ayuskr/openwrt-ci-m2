#!/bin/bash
set -e

cd openwrt || exit 1

cat >> feeds.conf.default <<'EOF'
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git
src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git
EOF

mkdir -p package/custom

git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/custom/luci-app-mosdns
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/custom/luci-app-lucky
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/custom/luci-app-gecoosac
