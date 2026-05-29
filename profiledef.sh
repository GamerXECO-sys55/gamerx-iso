#!/usr/bin/env bash
# shellcheck disable=SC2034
# GamerX OS · archiso profile definition

iso_name="gamerx-os"
iso_label="GAMERX_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="GamerX OS <https://github.com/GamerXECO-sys55/gamerx-os>"
iso_application="GamerX OS Live/Install"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="gamerx"
buildmodes=('iso')
# Modernized — modern archiso collapses the old per-firmware modes into
# 'bios.syslinux' (covers MBR + El Torito) and 'uefi.grub' (covers ESP +
# El Torito + ia32 + x64).
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/gamerx-live-autostart"]="0:0:755"
  ["/usr/local/bin/gamerx-collect-logs"]="0:0:755"
  ["/etc/sudoers.d/g_wheel"]="0:0:440"
)
