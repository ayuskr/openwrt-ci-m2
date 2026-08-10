#!/bin/bash
set -e

cd openwrt || exit 1

# Daed 需要 clang 编译 eBPF 相关组件。
# CONFIG_LLVM_HOST_PATH="/usr" 会使用 /usr/bin/clang。
sudo apt-get update
sudo apt-get install -y clang llvm lld

# 移除不再使用的 PassWall、dae 和错误的 daed feed。
sed -i '/passwall_packages/d' feeds.conf.default
sed -i '/passwall_luci/d' feeds.conf.default
sed -i '/^src-git dae /d' feeds.conf.default
sed -i '/^src-git daed /d' feeds.conf.default

mkdir -p package/custom

# 清理旧的第三方源码，避免重复目录或缓存残留。
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

# Daed LuCI plugin, daemon, GeoIP and GeoSite packages
git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-daed \
  package/custom/luci-app-daed

# Fail early when the Daed source was not downloaded correctly.
test -d package/custom/luci-app-daed
test -n "$(find package/custom/luci-app-daed -name Makefile -type f -print -quit)"

# Print the actual Daed package definitions into the Actions log.
grep -R \
  --include='Makefile' \
  -E 'define Package/(luci-app-daed|daed|daed-geoip|daed-geosite)' \
  package/custom/luci-app-daed || true

# Confirm the compiler that will be used by bpf-headers.
clang --version
