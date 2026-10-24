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

for unit in vscode-autoupdate.service vscode-autoupdate.timer; do
  echo "install $here/systemd/$unit -> /etc/systemd/system/$unit"
  install -m 644 "$here/systemd/$unit" "/etc/systemd/system/$unit"
done

systemctl daemon-reload
systemctl enable --now vscode-autoupdate.timer
systemctl list-timers vscode-autoupdate.timer --no-pager
