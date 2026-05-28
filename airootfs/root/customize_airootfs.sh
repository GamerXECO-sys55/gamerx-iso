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
if command -v plymouth-set-default-theme &>/dev/null; then
    if [[ -d /usr/share/plymouth/themes/gamerx ]]; then
        plymouth-set-default-theme -R gamerx || \
            plymouth-set-default-theme gamerx || true
    fi
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

# --- Live welcome + Calamares autostart ------------------------------------
# Drop a Hyprland custom-snippet that fires off a notification + Calamares
# a few seconds after first login. Hypr sources ~/.config/hypr/custom/*.
mkdir -p /home/gamerx/.config/hypr/custom
cat > /home/gamerx/.config/hypr/custom/00-live.conf <<'EOF'
# GamerX OS · live ISO welcome + auto-launch installer
# Removed automatically by gamerx-welcome on the first installed boot.

exec-once = sleep 4 && notify-send -i system-software-install \
              "Welcome to GamerX OS Live" \
              "This is the live preview. The installer will open in a moment."

# Auto-launch Calamares 8s after Hyprland comes up.
exec-once = sleep 8 && pkexec calamares >/dev/null 2>&1 &
EOF
chown -R gamerx:gamerx /home/gamerx/.config 2>/dev/null || true

# --- Done -------------------------------------------------------------------
exit 0
