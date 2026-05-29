#!/usr/bin/env bash
# Build the GamerX OS ISO via mkarchiso.
# Usage: scripts/build.sh [output_dir]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OUT_DIR="${1:-${REPO_ROOT}/out}"
WORK_DIR="${REPO_ROOT}/.work"

mkdir -p "$OUT_DIR" "$WORK_DIR"

# mkarchiso needs root for chroot operations.
if [[ $EUID -ne 0 ]]; then
  echo "mkarchiso needs root. Re-running with sudo."
  exec sudo bash "$0" "$@"
fi

# --- Pre-build: ensure unicode.pf2 is bundled in the iso grub directory ----
# Without this, the gating `loadfont unicode.pf2` in grub.cfg fails and the
# whole graphics + theme stack is skipped (text-mode GRUB → "Arch Linux"
# fallback). mkarchiso doesn't copy this file automatically.
if [[ -f /usr/share/grub/unicode.pf2 ]]; then
  install -dm755 "$REPO_ROOT/grub/fonts"
  install -m644 /usr/share/grub/unicode.pf2 "$REPO_ROOT/grub/fonts/unicode.pf2"
elif [[ -f /usr/share/grub/ascii.pf2 ]]; then
  install -dm755 "$REPO_ROOT/grub/fonts"
  install -m644 /usr/share/grub/ascii.pf2 "$REPO_ROOT/grub/fonts/unicode.pf2"
else
  echo "warning: no unicode.pf2 / ascii.pf2 found on host. GRUB graphics may fall back to text mode."
fi

echo "=== Building GamerX OS ISO ==="
echo "  profile : $REPO_ROOT"
echo "  work    : $WORK_DIR"
echo "  output  : $OUT_DIR"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$REPO_ROOT"

# --- Post-build: hand ownership back to the invoking user ------------------
# mkarchiso runs as root and creates root-owned files in OUT_DIR. Without this
# chown back, the user can't write into OUT_DIR (e.g. test-qemu.sh's qemu-share
# subdir creation fails with EACCES).
if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "${SUDO_USER}:${SUDO_USER}" "$OUT_DIR" "$WORK_DIR" 2>/dev/null || true
fi
