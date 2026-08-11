# Daed
rm -rf package/custom/luci-app-dae
rm -rf package/custom/luci-app-daed

git clone --depth=1 \
  https://github.com/QiuSimons/luci-app-daed \
  package/custom/luci-app-daed

# 确认源码和包定义存在
test -n "$(find package/custom/luci-app-daed -name Makefile -type f -print -quit)"

grep -R -n \
  --include='Makefile' \
  -E 'Package/(luci-app-daed|daed)|v2ray-(geoip|geosite)' \
  package/custom/luci-app-daed || true
