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

echo "=== Building GamerX OS ISO ==="
echo "  profile : $REPO_ROOT"
echo "  work    : $WORK_DIR"
echo "  output  : $OUT_DIR"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$REPO_ROOT"
