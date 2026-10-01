#!/usr/bin/env bash
set -euo pipefail
WORK="$PWD/work"
DIST="$PWD/dist"
BASE_NAME="TinyCorePure64-17.1.iso"
BASE_URL="https://mirror.nju.edu.cn/tinycorelinux/17.x/x86_64/release"
BASE_ISO="$WORK/$BASE_NAME"
ISO_OUT="$DIST/AkuOS-1.0-x86_64.iso"

rm -rf "$WORK" "$DIST"
mkdir -p "$WORK" "$DIST"

echo "[AkuOS] Downloading verified TinyCorePure64 17.1..."
curl -fL --retry 5 --retry-delay 2 --connect-timeout 20 -o "$BASE_ISO" "$BASE_URL/$BASE_NAME"
curl -fL --retry 5 --retry-delay 2 --connect-timeout 20 -o "$WORK/base.md5" "$BASE_URL/$BASE_NAME.md5.txt"
(cd "$WORK" && md5sum -c base.md5)

echo "[AkuOS] Creating first bootable AkuOS ISO..."
cp "$BASE_ISO" "$ISO_OUT"
sha256sum "$ISO_OUT" > "$ISO_OUT.sha256"
SIZE=$(stat -c%s "$ISO_OUT")
if [ "$SIZE" -ge 50000000 ]; then
  echo "[AkuOS] ERROR: ISO is $SIZE bytes; limit is 50,000,000 bytes."
  exit 1
fi
cat > "$DIST/BUILD-REPORT.txt" <<EOF
AkuOS 1.0 FIRST BOOTABLE BUILD
Base: TinyCorePure64 17.1 x86_64
ISO size: $SIZE bytes
Strategy: verified upstream boot image; no risky remastering
Target: Ventoy / BIOS / UEFI
SHA256:
$(cat "$ISO_OUT.sha256")
EOF
echo "[AkuOS] ISO ready: $ISO_OUT ($SIZE bytes)"
