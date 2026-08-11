#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Configuration
# =========================================================

readonly MOSDNS_REPO="https://github.com/sbwml/luci-app-mosdns.git"
readonly LUCKY_REPO="https://github.com/gdy666/luci-app-lucky.git"
readonly GECOOSAC_REPO="https://github.com/laipeng668/luci-app-gecoosac.git"
readonly AURORA_REPO="https://github.com/eamonxg/luci-theme-aurora.git"
readonly DAED_REPO="https://github.com/QiuSimons/luci-app-daed.git"

# This daed revision produces an empty wing/webrender/web directory.
readonly BROKEN_DAED_REVISION="671e65d2fdcd62fe6a3ec18ecda209c5addea898"

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

echo "===== Installing host dependencies ====="

sudo apt-get update

sudo apt-get install -y \
    build-essential \
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
    unzip \
    rsync \
    file

# =========================================================
# Validate LLVM/BPF tools
# =========================================================

echo "===== Validating LLVM tools ====="

for tool in clang llvm-config llvm-strip; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "ERROR: Required tool was not found: ${tool}" >&2
        exit 1
    fi

    echo "${tool}: $(command -v "${tool}")"
done

if [ ! -x /usr/bin/clang ]; then
    echo "ERROR: CONFIG_BPF_TOOLCHAIN_HOST_PATH=/usr requires /usr/bin/clang." >&2
    exit 1
fi

/usr/bin/clang --version
llvm-config --version
llvm-strip --version

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

rm -rf \
    feeds/dae \
    feeds/daed \
    package/feeds/dae \
    package/feeds/daed

# =========================================================
# Prepare custom package directory
# =========================================================

echo "===== Preparing custom packages ====="

mkdir -p package/custom

rm -rf \
    package/custom/luci-app-mosdns \
    package/custom/luci-app-lucky \
    package/custom/luci-app-gecoosac \
    package/custom/luci-theme-aurora \
    package/custom/luci-app-dae \
    package/custom/luci-app-daed

# =========================================================
# Clone custom packages
# =========================================================

echo "===== Cloning MosDNS ====="

git clone \
    --depth=1 \
    "${MOSDNS_REPO}" \
    package/custom/luci-app-mosdns

echo "===== Cloning Lucky ====="

git clone \
    --depth=1 \
    "${LUCKY_REPO}" \
    package/custom/luci-app-lucky

echo "===== Cloning GecoosAC ====="

git clone \
    --depth=1 \
    "${GECOOSAC_REPO}" \
    package/custom/luci-app-gecoosac

echo "===== Cloning Aurora theme ====="

git clone \
    --depth=1 \
    "${AURORA_REPO}" \
    package/custom/luci-theme-aurora

# A complete history is required to locate the revision before the broken
# daed source update.
echo "===== Cloning Daed package repository ====="

git clone \
    "${DAED_REPO}" \
    package/custom/luci-app-daed

# =========================================================
# Pin luci-app-daed before the broken daed source update
# =========================================================

echo "===== Locating broken Daed package update ====="

BROKEN_PACKAGE_COMMIT="$(
    git -C package/custom/luci-app-daed \
        log \
        --all \
        --format='%H' \
        -S"${BROKEN_DAED_REVISION}" \
        -- daed/Makefile |
        head -n 1
)"

if [ -z "${BROKEN_PACKAGE_COMMIT}" ]; then
    echo "ERROR: Could not find the luci-app-daed commit that introduced:" >&2
    echo "ERROR: ${BROKEN_DAED_REVISION}" >&2
    exit 1
fi

if ! git -C package/custom/luci-app-daed \
    rev-parse "${BROKEN_PACKAGE_COMMIT}^" >/dev/null 2>&1; then
    echo "ERROR: The commit before ${BROKEN_PACKAGE_COMMIT} is unavailable." >&2
    exit 1
fi

DAED_PACKAGE_REVISION="$(
    git -C package/custom/luci-app-daed \
        rev-parse "${BROKEN_PACKAGE_COMMIT}^"
)"

echo "Broken package commit: ${BROKEN_PACKAGE_COMMIT}"
echo "Selected package commit: ${DAED_PACKAGE_REVISION}"

git -C package/custom/luci-app-daed \
    checkout \
    --detach \
    "${DAED_PACKAGE_REVISION}"

git -C package/custom/luci-app-daed \
    submodule update \
    --init \
    --recursive

# =========================================================
# Confirm the broken source revision is no longer selected
# =========================================================

echo "===== Checking selected Daed source definition ====="

if grep -R -F -q \
    "${BROKEN_DAED_REVISION}" \
    package/custom/luci-app-daed/daed \
    --include='Makefile'; then
    echo "ERROR: The selected package still uses the broken Daed revision:" >&2
    echo "ERROR: ${BROKEN_DAED_REVISION}" >&2
    exit 1
fi

# Extract the selected upstream source information for the log.
grep -R -nE \
    'PKG_NAME|PKG_VERSION|PKG_RELEASE|PKG_SOURCE_VERSION|PKG_SOURCE_URL|PKG_MIRROR_HASH' \
    package/custom/luci-app-daed/daed \
    --include='Makefile' \
    || true

# =========================================================
# Validate package sources
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

if [ ! -f package/custom/luci-app-daed/daed/Makefile ]; then
    echo "ERROR: Daed package Makefile is missing." >&2
    exit 1
fi

if [ -d package/custom/luci-app-dae ]; then
    echo "ERROR: luci-app-dae is present, but luci-app-daed is required." >&2
    exit 1
fi

# =========================================================
# Remove stale Daed downloads and build products
# =========================================================

echo "===== Removing stale Daed build data ====="

# The old archive uses PKG_MIRROR_HASH=skip, so OpenWrt may reuse it.
# Delete it to force downloading the source selected by the pinned Makefile.
rm -f dl/daed-*.tar.gz

rm -rf \
    build_dir/target-*/daed-* \
    tmp/.daed-*.flock

find staging_dir \
    -type f \
    \( -name '*daed*' -o -name '.daed*' \) \
    -delete \
    2>/dev/null \
    || true

# =========================================================
# Diagnostics
# =========================================================

echo "===== Selected luci-app-daed revision ====="

git -C package/custom/luci-app-daed rev-parse HEAD
git -C package/custom/luci-app-daed log -1 --oneline

echo "===== Selected Daed source definition ====="

grep -R -nE \
    'PKG_NAME|PKG_VERSION|PKG_RELEASE|PKG_SOURCE|PKG_SOURCE_VERSION|PKG_SOURCE_URL|PKG_MIRROR_HASH' \
    package/custom/luci-app-daed/daed \
    --include='Makefile' \
    || true

echo "===== Daed package definitions ====="

grep -R -nE \
    'define Package/(luci-app-daed|daed)|DEPENDS|PROVIDES|CONFLICTS' \
    package/custom/luci-app-daed \
    --include='Makefile' \
    || true

echo "===== Daed patches ====="

find package/custom/luci-app-daed/daed \
    -type f \
    \( -name '*.patch' -o -name '*.diff' \) \
    -print \
    | sort \
    || true

echo "===== Custom packages ====="

find package/custom \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' \
    | sort

echo "===== diy.sh completed successfully ====="
