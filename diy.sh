#!/bin/bash
cd openwrt

# Passwall 官方源（必须用这个）
echo "src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main" >> feeds.conf.default

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/mosdns

# Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky

# Gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/gecoosac
