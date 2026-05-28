# gamerx-iso

archiso profile for GamerX OS — builds the bootable ISO.

This profile is forked from upstream `releng` and modified for GamerX OS:
themed branding, custom user (`gamerx`), `[gamerx-core]` repo enabled, SDDM
autologin into Hyprland with the GamerX shell.

## Layout

```
profiledef.sh             iso_name=gamerx-os, label GAMERX_<YYYYMM>
pacman.conf               base Arch repos + [gamerx-core]
packages.x86_64           live ISO package list
airootfs/                 overlay merged into the live root filesystem
  etc/{passwd,shadow,group,hostname,motd,sudoers.d/g_wheel}
  etc/sddm.conf.d/gamerx.conf       — autologin gamerx into Hyprland
  etc/systemd/system/multi-user.target.wants/{sddm,NetworkManager}.service
  etc/skel/.config/hypr/hyprland.conf — sources gamerx-shell modular configs
  home/gamerx/.config/hypr/local/00-live.conf — live-only welcome notify
  usr/local/bin/gamerx-live-autostart — bootstraps theme state on first login

efiboot/, grub/, syslinux/ — boot loaders (inherited from releng, branded)

scripts/
  build.sh                — wrapper around mkarchiso
  test-qemu.sh            — boot the latest ISO in QEMU
```

## Build the ISO

```bash
sudo scripts/build.sh
# Output: out/gamerx-os-<calver>-x86_64.iso
```

Build time is ~10–20 minutes on a modern machine. The build container fetches
all packages from official Arch mirrors plus our `[gamerx-core]` channel, so
it always gets the latest published versions.

## Test in QEMU

```bash
scripts/test-qemu.sh
```

Requires `qemu-system-x86_64` and `edk2-ovmf` for UEFI. KVM acceleration on by
default.

## Status

🛠 Phase 6 — first build attempts pending.
