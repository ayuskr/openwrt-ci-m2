#!/bin/bash
set -e

cd openwrt || exit 1

mkdir -p package/custom

# MosDNS
git clone --depth=1 \
  https://github.com/sbwml/luci-app-mosdns \
  package/custom/luci-app-mosdns

# Lucky
git clone --depth=1 \
  https://github.com/gdy666/luci-app-lucky \
  package/custom/luci-app-lucky

# GecoosAC
git clone --depth=1 \
  https://github.com/laipeng668/luci-app-gecoosac \
  package/custom/luci-app-gecoosac

# Aurora 主题
git clone --depth=1 \
  https://github.com/eamonxg/luci-theme-aurora \
  package/custom/luci-theme-aurora

# Daed
# 该源码提供 luci-app-daed、daed、daed-geoip 和 daed-geosite
git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-dae \
  package/custom/luci-app-daed
