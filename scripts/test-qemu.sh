#!/usr/bin/env bash
# Boot the latest built ISO in QEMU/KVM (UEFI by default).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OUT_DIR="${1:-${REPO_ROOT}/out}"

ISO=$(ls -t "$OUT_DIR"/gamerx-os-*.iso 2>/dev/null | head -n1 || true)
if [[ -z "$ISO" ]]; then
  echo "No ISO found in $OUT_DIR. Run scripts/build.sh first."
  exit 1
fi

OVMF_CODE=/usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS_TEMPLATE=/usr/share/edk2/x64/OVMF_VARS.4m.fd
WORK=$(mktemp -d)
cp "$OVMF_VARS_TEMPLATE" "$WORK/OVMF_VARS.fd"

echo "=== Booting $ISO in QEMU (UEFI, 4G RAM, KVM) ==="
qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 4 -m 4G \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd" \
  -drive media=cdrom,file="$ISO",readonly=on \
  -boot d \
  -device virtio-vga \
  -device virtio-net,netdev=n0 -netdev user,id=n0 \
  -device intel-hda -device hda-output \
  -name "GamerX OS Live"

rm -rf "$WORK"
