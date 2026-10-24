#!/usr/bin/env bash
# Install the daily VS Code Flatpak update timer as a system unit. Run as ./install.sh; it re-runs itself through sudo.
# Copies (not links) the units into /etc, which survives SteamOS updates and doesn't depend on /home being mounted.
# Re-run after editing anything here (it is idempotent).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Not root; re-running through sudo"
  exec sudo "$here/$(basename "$0")" "$@"
fi

install -d /etc/vscode-autoupdate
install -m 755 "$here/bin/vscode-patch-product" /etc/vscode-autoupdate/vscode-patch-product
for unit in vscode-autoupdate.service vscode-autoupdate.timer vscode-patch-product.service vscode-patch-product.path; do
  echo "install $here/systemd/$unit -> /etc/systemd/system/$unit"
  install -m 644 "$here/systemd/$unit" "/etc/systemd/system/$unit"
done

systemctl daemon-reload
systemctl enable --now vscode-autoupdate.timer
systemctl enable --now vscode-patch-product.path
/etc/vscode-autoupdate/vscode-patch-product   # patch the current install now; the path unit handles later updates

# The click handler belongs to the real user, not root.
user="${SUDO_USER:-}"
[[ -n "$user" && "$user" != root ]] || { echo "Run this as your normal user (it uses sudo itself), not as root directly." >&2; exit 1; }
user_home="$(getent passwd "$user" | cut -d: -f6)"
apps="$user_home/.local/share/applications"
sudo -u "$user" mkdir -p "$apps"
sed "s|@BIN@|$here/bin|" "$here/systemd/vscode-update.desktop" | sudo -u "$user" tee "$apps/vscode-flatpak-update.desktop" >/dev/null
sudo -u "$user" rm -f "$apps/vscode-update-probe.desktop"
sudo -u "$user" update-desktop-database "$apps"
sudo -u "$user" xdg-mime default vscode-flatpak-update.desktop x-scheme-handler/vscode-flatpak-update
systemctl list-timers vscode-autoupdate.timer --no-pager
