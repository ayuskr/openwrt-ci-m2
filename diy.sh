#!/bin/bash
set -e

cd openwrt || exit 1

# Daed 需要 clang 编译 eBPF 相关组件
sudo apt-get update
sudo apt-get install -y clang llvm lld

mkdir -p staging_dir/host/bin
ln -sf "$(command -v clang)" staging_dir/host/bin/clang
ln -sf "$(command -v llvm-config)" staging_dir/host/bin/llvm-config
ln -sf "$(command -v llvm-strip)" staging_dir/host/bin/llvm-strip

# 清理不再使用或曾经添加错误的 feed
sed -i '/passwall_packages/d' feeds.conf.default
sed -i '/passwall_luci/d' feeds.conf.default
sed -i '/^src-git daed /d' feeds.conf.default
sed -i '/^src-git dae /d' feeds.conf.default

mkdir -p package/custom

# 清理旧插件目录，避免 Actions 缓存或重复源码影响构建
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

# Aurora 主题
git clone --depth=1 \
  https://github.com/eamonxg/luci-theme-aurora \
  package/custom/luci-theme-aurora

# Daed LuCI 插件、Daed 主程序及 GeoIP / GeoSite 数据
git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-daed \
  package/custom/luci-app-daed

# 在 feeds 更新前验证 Daed 源码已正确下载
test -d package/custom/luci-app-daed
test -n "$(find package/custom/luci-app-daed -name Makefile -type f -print -quit)"

# 输出 Daed 包定义，便于 Actions 日志确认实际可用包
grep -R \
  --include='Makefile' \
  -E 'define Package/(luci-app-daed|daed|daed-geoip|daed-geosite)' \
  package/custom/luci-app-daed
