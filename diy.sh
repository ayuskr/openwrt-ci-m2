#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Locate OpenWrt source directory
# =========================================================

if [ -f "include/toplevel.mk" ]; then
    OPENWRT_DIR="$(pwd)"
elif [ -d "openwrt" ] && [ -f "openwrt/include/toplevel.mk" ]; then
    cd openwrt
    OPENWRT_DIR="$(pwd)"
else
    echo "ERROR: OpenWrt source directory was not found." >&2
    exit 1
fi

echo "===== OpenWrt source directory ====="
echo "${OPENWRT_DIR}"

# =========================================================
# Install host dependencies
# =========================================================

echo "===== Installing build dependencies ====="

sudo apt-get update

sudo apt-get install -y \
    clang \
    llvm \
    lld \
    libelf-dev \
    zlib1g-dev \
    pkg-config \
    git \
    ca-certificates \
    curl \
    wget \
    xz-utils \
    unzip

# =========================================================
# Validate host LLVM tools
# =========================================================

echo "===== Validating host LLVM tools ====="

if [ ! -x /usr/bin/clang ]; then
    echo "ERROR: /usr/bin/clang was not found." >&2
    exit 1
fi

if ! command -v llvm-strip >/dev/null 2>&1; then
    echo "ERROR: llvm-strip was not found." >&2
    exit 1
fi

if ! command -v llvm-config >/dev/null 2>&1; then
    echo "ERROR: llvm-config was not found." >&2
    exit 1
fi

echo "clang: $(command -v clang)"
echo "llvm-strip: $(command -v llvm-strip)"
echo "llvm-config: $(command -v llvm-config)"

/usr/bin/clang --version
llvm-strip --version
llvm-config --version

# =========================================================
# Remove obsolete feed definitions
# =========================================================

echo "===== Cleaning obsolete feed definitions ====="

clean_feed_file() {
    local feed_file="$1"

    if [ ! -f "${feed_file}" ]; then
        return
    fi

    sed -i \
        -e '/^[[:space:]]*src-git[[:space:]]\+passwall_packages[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]\+passwall_luci[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]\+dae[[:space:]]/d' \
        -e '/^[[:space:]]*src-git[[:space:]]\+daed[[:space:]]/d' \
        "${feed_file}"
}

clean_feed_file "feeds.conf.default"
clean_feed_file "feeds.conf"

# Remove old feed directories and package links.
rm -rf \
    feeds/dae \
    feeds/daed \
    package/feeds/dae \
    package/feeds/daed

# =========================================================
# Prepare custom package directory
# =========================================================

echo "===== Preparing custom package directory ====="

mkdir -p package/custom

rm -rf \
    package/custom/luci-app-mosdns \
    package/custom/luci-app-lucky \
    package/custom/luci-app-gecoosac \
    package/custom/luci-theme-aurora \
    package/custom/luci-app-dae \
    package/custom/luci-app-daed

# =========================================================
# Clone MosDNS
# =========================================================

echo "===== Cloning MosDNS ====="

git clone \
    --depth=1 \
    https://github.com/sbwml/luci-app-mosdns.git \
    package/custom/luci-app-mosdns

# =========================================================
# Clone Lucky
# =========================================================

echo "===== Cloning Lucky ====="

git clone \
    --depth=1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/custom/luci-app-lucky

# =========================================================
# Clone GecoosAC
# =========================================================

echo "===== Cloning GecoosAC ====="

git clone \
    --depth=1 \
    https://github.com/laipeng668/luci-app-gecoosac.git \
    package/custom/luci-app-gecoosac

# =========================================================
# Clone Aurora theme
# =========================================================

echo "===== Cloning Aurora theme ====="

git clone \
    --depth=1 \
    https://github.com/eamonxg/luci-theme-aurora.git \
    package/custom/luci-theme-aurora

# =========================================================
# Clone Daed
# =========================================================

echo "===== Cloning Daed ====="

git clone \
    --depth=1 \
    --recurse-submodules \
    --shallow-submodules \
    https://github.com/QiuSimons/luci-app-daed.git \
    package/custom/luci-app-daed

git -C package/custom/luci-app-daed \
    submodule update \
    --init \
    --recursive

# =========================================================
# Validate custom package sources
# =========================================================

validate_package_source() {
    local package_name="$1"
    local package_path="$2"

    if [ ! -d "${package_path}" ]; then
        echo "ERROR: ${package_name} directory is missing: ${package_path}" >&2
        exit 1
    fi

    if ! find "${package_path}" \
        -type f \
        -name Makefile \
        -print \
        -quit |
        grep -q .; then
        echo "ERROR: No Makefile found for ${package_name}: ${package_path}" >&2
        exit 1
    fi

    echo "OK: ${package_name}"
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
# Ensure dae was not added accidentally
# =========================================================

echo "===== Checking for incorrect dae package ====="

if [ -d package/custom/luci-app-dae ]; then
    echo "ERROR: luci-app-dae is present, but luci-app-daed is required." >&2
    exit 1
fi

if [ ! -d package/custom/luci-app-daed ]; then
    echo "ERROR: luci-app-daed is missing." >&2
    exit 1
fi

echo "OK: luci-app-daed is present"
echo "OK: luci-app-dae is absent"

# =========================================================
# Daed source diagnostics
# =========================================================

echo "===== Daed source revision ====="

git -C package/custom/luci-app-daed rev-parse HEAD
git -C package/custom/luci-app-daed log -1 --oneline

echo "===== Daed repository status ====="

git -C package/custom/luci-app-daed status --short
git -C package/custom/luci-app-daed submodule status --recursive || true

echo "===== Daed package source definition ====="

grep -R -nE \
    'PKG_NAME|PKG_VERSION|PKG_RELEASE|PKG_SOURCE|PKG_SOURCE_VERSION|PKG_SOURCE_URL|PKG_MIRROR_HASH|daeuniverse/daed|dae-wing' \
    package/custom/luci-app-daed/daed \
    --include='Makefile' \
    || true

echo "===== Daed package definitions ====="

grep -R -nE \
    'define Package/(luci-app-daed|daed)|DEPENDS|PROVIDES|CONFLICTS' \
    package/custom/luci-app-daed \
    --include='Makefile' \
    || true

echo "===== Daed Makefiles ====="

find package/custom/luci-app-daed \
    -type f \
    -name Makefile \
    -print \
    | sort

echo "===== Daed patches ====="

find package/custom/luci-app-daed/daed \
    -type f \
    \( -name '*.patch' -o -name '*.diff' \) \
    -print \
    | sort \
    || true

echo "===== Daed submodule declarations ====="

find package/custom/luci-app-daed \
    -type f \
    -name '.gitmodules' \
    -print \
    -exec sed -n '1,240p' {} \; \
    || true

echo "===== Daed web-related build definitions ====="

grep -R -nE \
    'webrender|go generate|go:embed|npm|pnpm|yarn|web/' \
    package/custom/luci-app-daed \
    --include='Makefile' \
    --include='*.patch' \
    --include='*.diff' \
    --include='*.go' \
    --include='package.json' \
    || true

# =========================================================
# Display custom package summary
# =========================================================

echo "===== Custom packages ====="

find package/custom \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' \
    | sort

echo "===== diy.sh completed successfully ====="
