#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Enter the OpenWrt source directory
# =========================================================

if [ -f "include/toplevel.mk" ]; then
    echo "Already in the OpenWrt source directory."
elif [ -d "openwrt" ] && [ -f "openwrt/include/toplevel.mk" ]; then
    cd openwrt
else
    echo "ERROR: OpenWrt source directory was not found." >&2
    exit 1
fi

echo "OpenWrt source directory: $(pwd)"

# =========================================================
# Install host build dependencies required by Daed/eBPF
# =========================================================

sudo apt-get update

sudo apt-get install -y \
    clang \
    llvm \
    lld \
    libelf-dev \
    zlib1g-dev \
    pkg-config

# The BPF host toolchain path in m2.config is /usr.
if [ ! -x /usr/bin/clang ]; then
    echo "ERROR: /usr/bin/clang does not exist." >&2
    exit 1
fi

echo "===== Host clang ====="
/usr/bin/clang --version

# =========================================================
# Clean obsolete feed definitions
# =========================================================

if [ -f feeds.conf.default ]; then
    sed -i \
        -e '/^[[:space:]]*src-git[[:space:]].*passwall/d' \
        -e '/^[[:space:]]*src-git[[:space:]]passwall_packages[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]passwall_luci[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]dae[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]daed[[:space:]]/d' \
        feeds.conf.default
fi

if [ -f feeds.conf ]; then
    sed -i \
        -e '/^[[:space:]]*src-git[[:space:]].*passwall/d' \
        -e '/^[[:space:]]*src-git[[:space:]]passwall_packages[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]passwall_luci[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]dae[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]daed[[:space:]]/d' \
        feeds.conf
fi

# Remove old downloaded feed directories that caused:
# find: 'feeds/daed': No such file or directory
rm -rf feeds/dae
rm -rf feeds/daed

# Remove stale package links left by previous feed installations.
rm -rf package/feeds/dae
rm -rf package/feeds/daed

# =========================================================
# Prepare custom package directory
# =========================================================

mkdir -p package/custom

# Remove old copies to make repeated CI builds deterministic.
rm -rf package/custom/luci-app-mosdns
rm -rf package/custom/luci-app-lucky
rm -rf package/custom/luci-app-gecoosac
rm -rf package/custom/luci-theme-aurora
rm -rf package/custom/luci-app-dae
rm -rf package/custom/luci-app-daed

# =========================================================
# MosDNS
# =========================================================

echo "===== Cloning MosDNS ====="

git clone \
    --depth=1 \
    https://github.com/sbwml/luci-app-mosdns.git \
    package/custom/luci-app-mosdns

# =========================================================
# Lucky
# =========================================================

echo "===== Cloning Lucky ====="

git clone \
    --depth=1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/custom/luci-app-lucky

# =========================================================
# GecoosAC
# =========================================================

echo "===== Cloning GecoosAC ====="

git clone \
    --depth=1 \
    https://github.com/laipeng668/luci-app-gecoosac.git \
    package/custom/luci-app-gecoosac

# =========================================================
# Aurora theme
# =========================================================

echo "===== Cloning Aurora theme ====="

git clone \
    --depth=1 \
    https://github.com/eamonxg/luci-theme-aurora.git \
    package/custom/luci-theme-aurora

# =========================================================
# Daed
# =========================================================

echo "===== Cloning Daed ====="

git clone \
    --depth=1 \
    https://github.com/QiuSimons/luci-app-daed.git \
    package/custom/luci-app-daed

# =========================================================
# Validate downloaded packages
# =========================================================

validate_package_source() {
    local package_name="$1"
    local package_path="$2"

    if [ ! -d "$package_path" ]; then
        echo "ERROR: $package_name directory does not exist: $package_path" >&2
        exit 1
    fi

    if ! find "$package_path" -type f -name Makefile -print -quit |
        grep -q .; then
        echo "ERROR: No Makefile found for $package_name: $package_path" >&2
        exit 1
    fi

    echo "OK: $package_name"
}

echo "===== Validating custom package sources ====="

validate_package_source \
    "MosDNS" \
    "package/custom/luci-app-mosdns"

validate_package_source \
    "Lucky" \
    "package/custom/luci-app-lucky"

validate_package_source \
    "GecoosAC" \
    "package/custom/luci-app-gecoosac"

validate_package_source \
    "Aurora theme" \
    "package/custom/luci-theme-aurora"

validate_package_source \
    "Daed" \
    "package/custom/luci-app-daed"

# =========================================================
# Display the actual Daed package definitions
# =========================================================

echo "===== Daed Makefiles ====="

find package/custom/luci-app-daed \
    -type f \
    -name Makefile \
    -print

echo "===== Daed package definitions and dependencies ====="

grep -R -nE \
    'define Package/(luci-app-daed|daed)|DEPENDS.*(daed|v2ray-geoip|v2ray-geosite)|v2ray-(geoip|geosite)' \
    package/custom/luci-app-daed \
    --include='Makefile' || true

# =========================================================
# Ensure the incorrect dae source is not present
# =========================================================

if [ -d package/custom/luci-app-dae ]; then
    echo "ERROR: luci-app-dae must not be present." >&2
    exit 1
fi

# =========================================================
# Final summary
# =========================================================

echo "===== Custom packages ready ====="

find package/custom \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' \
    | sort

echo "===== diy.sh completed successfully ====="
