#!/usr/bin/env bash
# Boot the latest built ISO in QEMU/KVM (UEFI by default).
#
# This script also exposes a HOST FOLDER inside the VM so logs can be copied
# back to your machine. Inside the live session run:
#
#     gamerx-collect-logs /mnt/host
#
# and the tarball will appear in <repo>/out/qemu-share/ on the host.
#
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OUT_DIR="${1:-${REPO_ROOT}/out}"
SHARE_DIR="${OUT_DIR}/qemu-share"
# OUT_DIR may be root-owned from a previous build; handle gracefully.
if ! mkdir -p "$SHARE_DIR" 2>/dev/null; then
  echo "warning: $OUT_DIR is not writable by $(whoami) — fixing with sudo"
  sudo chown -R "$(whoami)":"$(whoami)" "$OUT_DIR"
  mkdir -p "$SHARE_DIR"
fi
chmod 0777 "$SHARE_DIR"

ISO=$(ls -t "$OUT_DIR"/gamerx-os-*.iso 2>/dev/null | head -n1 || true)
if [[ -z "$ISO" ]]; then
  echo "No ISO found in $OUT_DIR. Run scripts/build.sh first."
  exit 1
fi

# Persistent virtual disk so Calamares has somewhere to install. Created on
# first run (40G qcow2, sparse → ~200 KB until written to).
VDISK="${OUT_DIR}/gamerx-vm.qcow2"
if [[ ! -f "$VDISK" ]]; then
  echo "    Creating 40G virtual disk: $VDISK"
  qemu-img create -f qcow2 "$VDISK" 40G >/dev/null
fi

# OVMF firmware paths — different distros put them in different places.
OVMF_CODE=""
for c in /usr/share/edk2/x64/OVMF_CODE.4m.fd \
         /usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd \
         /usr/share/OVMF/OVMF_CODE.4m.fd \
         /usr/share/OVMF/OVMF_CODE.fd; do
  if [[ -f "$c" ]]; then OVMF_CODE="$c"; break; fi
done
OVMF_VARS_TEMPLATE=""
for v in /usr/share/edk2/x64/OVMF_VARS.4m.fd \
         /usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd \
         /usr/share/OVMF/OVMF_VARS.4m.fd \
         /usr/share/OVMF/OVMF_VARS.fd; do
  if [[ -f "$v" ]]; then OVMF_VARS_TEMPLATE="$v"; break; fi
done
if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS_TEMPLATE" ]]; then
  echo "warning: edk2 OVMF firmware not found. Install 'edk2-ovmf' package, or this will fall back to BIOS."
fi

WORK=$(mktemp -d)
[[ -n "$OVMF_VARS_TEMPLATE" ]] && cp "$OVMF_VARS_TEMPLATE" "$WORK/OVMF_VARS.fd"

echo "=== Booting $ISO in QEMU (UEFI, 4G RAM, KVM) ==="
echo "    Host share dir : $SHARE_DIR"
echo "    Inside the VM  : mount with"
echo "        sudo mkdir -p /mnt/host"
echo "        sudo mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/host"
echo "    Then collect logs:  gamerx-collect-logs /mnt/host"

QEMU_ARGS=(
  -enable-kvm -cpu host -smp 4 -m 4G
  -drive media=cdrom,file="$ISO",readonly=on
  -drive if=virtio,format=qcow2,file="$VDISK"
  -boot d
  -device virtio-vga
  -device virtio-net,netdev=n0 -netdev user,id=n0
  -device intel-hda -device hda-output
  # 9p shared folder — exposed to the guest as the 'hostshare' device tag.
  -fsdev local,security_model=mapped,id=fsdev0,path="$SHARE_DIR"
  -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare
  -name "GamerX OS Live"
)
if [[ -n "$OVMF_CODE" && -f "$WORK/OVMF_VARS.fd" ]]; then
  QEMU_ARGS+=(
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
    -drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd"
  )
fi

qemu-system-x86_64 "${QEMU_ARGS[@]}"
rm -rf "$WORK"
