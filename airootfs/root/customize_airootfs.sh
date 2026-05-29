#!/usr/bin/env bash
# GamerX OS · live ISO chroot customization
# Pattern adapted from AxOS / Arch's archiso AUI fork.
# mkarchiso runs this inside the chroot at the end of pacstrap.
# After this script finishes, mkarchiso deletes it from the live ISO.

set -e -u

# --- Locales ----------------------------------------------------------------
# Uncomment the most-used locales so locale-gen has something to generate.
sed -i -E '/^# *(en_US|en_GB|de_DE|fr_FR|es_ES|it_IT|pt_PT|pt_BR|zh_CN|zh_TW|ja_JP|ko_KR|ru_RU|nl_NL|sv_SE|da_DK|fi_FI|nb_NO|pl_PL|hi_IN)/ s/^# *//' /etc/locale.gen
locale-gen >/dev/null 2>&1 || true

# --- Mirrorlist activate ----------------------------------------------------
sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist 2>/dev/null || true

# --- Live user --------------------------------------------------------------
# `gamerx` user, fish shell, sudo NOPASSWD via /etc/sudoers.d/g_wheel
# (already shipped in airootfs). Lock root password, give gamerx empty password
# for live convenience — Calamares replaces this on install.
if ! id gamerx &>/dev/null; then
    useradd -m -G wheel,storage,audio,video,input,seat,network,power,log -s /usr/bin/fish gamerx
fi
# Empty passwords on live media (mirrors AxOS/Arch live behaviour).
passwd -d root  >/dev/null 2>&1 || true
passwd -d gamerx >/dev/null 2>&1 || true

# Make sure home perms are right
chown -R gamerx:gamerx /home/gamerx 2>/dev/null || true

# --- Pacman keyring ---------------------------------------------------------
pacman-key --init    >/dev/null 2>&1 || true
pacman-key --populate >/dev/null 2>&1 || true

# --- Display manager (SDDM) -------------------------------------------------
# Proper enable — writes /etc/systemd/system/display-manager.service symlink
# the systemd way, no fragile manual-symlink-in-airootfs.
if [[ -e /usr/lib/systemd/system/sddm.service ]]; then
    systemctl enable sddm.service >/dev/null 2>&1 || true
fi

# --- NetworkManager / Bluetooth --------------------------------------------
[[ -e /usr/lib/systemd/system/NetworkManager.service ]] && systemctl enable NetworkManager.service >/dev/null 2>&1 || true
[[ -e /usr/lib/systemd/system/bluetooth.service       ]] && systemctl enable bluetooth.service       >/dev/null 2>&1 || true

# --- Plymouth: bake theme into initramfs ------------------------------------
# This is THE critical step that makes the splash actually show during boot
# (instead of the 1-2s flash we were getting). -R rebuilds initramfs.
#
# CRITICAL: archiso uses /etc/mkinitcpio.conf.d/archiso.conf (NOT
# /etc/mkinitcpio.conf) — that file ships from the mkinitcpio-archiso package
# and has NO plymouth hook by default. We patch it here to insert plymouth
# right after udev, then run mkinitcpio.
if [[ -f /etc/mkinitcpio.conf.d/archiso.conf ]]; then
    # 1. Add plymouth hook after udev
    sed -i -E 's/^HOOKS=\(base udev /HOOKS=(base udev plymouth /' /etc/mkinitcpio.conf.d/archiso.conf
    # 2. Add KMS modules so framebuffer comes up before plymouth tries to draw
    if ! grep -q '^MODULES=' /etc/mkinitcpio.conf.d/archiso.conf; then
        echo 'MODULES=(i915 amdgpu radeon nouveau virtio_gpu qxl bochs)' >> /etc/mkinitcpio.conf.d/archiso.conf
    fi
fi
if command -v plymouth-set-default-theme &>/dev/null; then
    if [[ -d /usr/share/plymouth/themes/gamerx ]]; then
        plymouth-set-default-theme gamerx || true
    fi
fi
# Rebuild ALL initramfs presets so the live ISO actually contains plymouth+theme
if command -v mkinitcpio &>/dev/null; then
    mkinitcpio -P || true
fi

# --- Plymouth handoff units (smooth Plymouth -> SDDM transition) -----------
# Without these, Plymouth quits the moment login-ready is reached and you get
# a black screen until SDDM paints. Enabling these targets the handoff.
[[ -e /usr/lib/systemd/system/plymouth-quit-wait.service ]] && systemctl enable plymouth-quit-wait.service >/dev/null 2>&1 || true
[[ -e /usr/lib/systemd/system/plymouth-quit.service      ]] && systemctl enable plymouth-quit.service      >/dev/null 2>&1 || true

# --- GRUB theme (for systems that boot from the *installed* GamerX) --------
# This only affects the OS once installed. The live ISO's GRUB is configured
# separately via grub/grub.cfg in the iso profile root.
if [[ -d /usr/share/grub/themes/gamerx ]] && [[ -e /etc/default/grub ]]; then
    sed -i -E 's|^[# ]*GRUB_THEME=.*$|GRUB_THEME="/usr/share/grub/themes/gamerx/theme.txt"|' /etc/default/grub
    grep -q '^GRUB_THEME=' /etc/default/grub || \
        echo 'GRUB_THEME="/usr/share/grub/themes/gamerx/theme.txt"' >> /etc/default/grub
    sed -i -E 's|^[# ]*GRUB_DISABLE_OS_PROBER=.*$|GRUB_DISABLE_OS_PROBER=false|' /etc/default/grub
fi

# --- /etc/skel -> /home/gamerx (force-sync after user creation) -------------
# useradd already copied skel; this re-copies for any custom files added late.
cp -rT /etc/skel /home/gamerx 2>/dev/null || true
chown -R gamerx:gamerx /home/gamerx 2>/dev/null || true

# --- Wire up Waybar / swaync configs to expected locations ------------------
# The packages install configs to /usr/share/gamerx-shell/{waybar,swaync}/styles/default/
# but these tools look in ~/.config/{waybar,swaync}/. Symlink them in skel and
# the gamerx home so they Just Work on first login.
for U in /etc/skel /home/gamerx; do
    install -dm755 "$U/.config/waybar"
    install -dm755 "$U/.config/swaync"
    if [[ -f /usr/share/gamerx-shell/waybar/styles/default/config.jsonc ]]; then
        ln -sf /usr/share/gamerx-shell/waybar/styles/default/config.jsonc "$U/.config/waybar/config.jsonc"
        ln -sf /usr/share/gamerx-shell/waybar/styles/default/style.css    "$U/.config/waybar/style.css"
    fi
    if [[ -f /usr/share/gamerx-shell/swaync/styles/default/config.json ]]; then
        ln -sf /usr/share/gamerx-shell/swaync/styles/default/config.json "$U/.config/swaync/config.json"
        ln -sf /usr/share/gamerx-shell/swaync/styles/default/style.css   "$U/.config/swaync/style.css"
    fi
done
chown -R gamerx:gamerx /home/gamerx/.config 2>/dev/null || true

# --- Live welcome + Calamares autostart ------------------------------------
# Now handled by /usr/bin/gamerx-shell-start which reads /etc/gamerx-live as
# its mode marker. Nothing to do here — the orchestrator covers it.

# --- Done -------------------------------------------------------------------
exit 0
