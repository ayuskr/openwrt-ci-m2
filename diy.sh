#!/bin/bash
set -e

cd openwrt || exit 1

mkdir -p package/custom

# 清理旧的 PassWall 和 Daed feed 配置
sed -i '/passwall_packages/d' feeds.conf.default
sed -i '/passwall_luci/d' feeds.conf.default
sed -i '/^src-git daed /d' feeds.conf.default
sed -i '/^src-git dae /d' feeds.conf.default

# 清理旧的插件源码
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

# Daed LuCI 插件及相关程序
git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-daed \
  package/custom/luci-app-daed

# 检查 Daed 源码是否成功下载
test -d package/custom/luci-app-daed
test -n "$(find package/custom/luci-app-daed -name Makefile -type f -print -quit)"

# 输出 Daed 源码中实际存在的 Makefile
find package/custom/luci-app-daed -name Makefile -type f -print
