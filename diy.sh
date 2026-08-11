#!/bin/bash
set -euo pipefail

cd openwrt || exit 1

# dae 的 eBPF 组件需要 clang、LLVM 和 lld。
sudo apt-get update
sudo apt-get install -y clang llvm lld

# 清除旧的 PassWall、dae 和 daed feed 配置。
sed -i '/passwall_packages/d' feeds.conf.default
sed -i '/passwall_luci/d' feeds.conf.default
sed -i '/^src-git dae /d' feeds.conf.default
sed -i '/^src-git daed /d' feeds.conf.default

mkdir -p package/custom

# 清除可能由缓存或旧脚本留下的第三方源码。
rm -rf package/custom/luci-app-mosdns
rm -rf package/custom/luci-app-lucky
rm -rf package/custom/luci-app-gecoosac
rm -rf package/custom/luci-theme-aurora
rm -rf package/custom/luci-app-dae
rm -rf package/custom/luci-app-daed

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

# Aurora theme
git clone --depth=1 \
  https://github.com/eamonxg/luci-theme-aurora \
  package/custom/luci-theme-aurora

# dae LuCI application
git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-dae \
  package/custom/luci-app-dae

# 检查第三方源码是否完整。
test -n "$(find package/custom/luci-app-mosdns -name Makefile -type f -print -quit)"
test -n "$(find package/custom/luci-app-lucky -name Makefile -type f -print -quit)"
test -n "$(find package/custom/luci-app-gecoosac -name Makefile -type f -print -quit)"
test -n "$(find package/custom/luci-theme-aurora -name Makefile -type f -print -quit)"
test -n "$(find package/custom/luci-app-dae -name Makefile -type f -print -quit)"

# 检查 BPF 编译器。配置中的路径为 /usr，因此实际程序必须存在于 /usr/bin。
test -x /usr/bin/clang
test -x /usr/bin/llvm-config

echo "===== Host clang ====="
/usr/bin/clang --version

echo "===== dae package definitions ====="
grep -R \
  --include='Makefile' \
  -nE 'luci-app-dae|Package/dae|v2ray-geoip|v2ray-geosite' \
  package/custom/luci-app-dae || true
