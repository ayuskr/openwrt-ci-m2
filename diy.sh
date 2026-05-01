#!/bin/bash
cd openwrt

echo "src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git" >> feeds.conf.default
echo "src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git" >> feeds.conf.default

git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/gecoosac
