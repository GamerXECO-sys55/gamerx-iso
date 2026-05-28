# gamerx-iso

archiso profile for GamerX OS — builds the bootable ISO.

This repo holds the [archiso](https://wiki.archlinux.org/title/Archiso) profile
that produces the GamerX OS installation image. It does not contain user-facing
code; everything here exists to assemble a bootable, themed live environment.

## Layout (planned)

```
profile/
├── airootfs/             # overlay merged into the live root filesystem
├── efiboot/              # UEFI boot loader configs
├── grub/                 # GRUB configs (BIOS + UEFI)
├── syslinux/             # legacy BIOS fallback
├── packages.x86_64       # what gets installed into the ISO
├── pacman.conf           # custom repos enabled (gamerx-core)
└── profiledef.sh         # archiso profile definition

scripts/
├── build.sh              # local ISO build wrapper
└── test-qemu.sh          # boot the ISO in QEMU
```

## Status

🚧 **Phase 6 — not started.** Comes after `gamerx-shell` and `gamerx-branding` are usable.

## See also

- [Meta repo](https://github.com/GamerXECO-sys55/gamerx-os) — spec, roadmap, decisions
- [archiso documentation](https://wiki.archlinux.org/title/Archiso)

## License

GPL-3.0
