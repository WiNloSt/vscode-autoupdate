# vscode-autoupdate

Keeps VS Code (the Flathub Flatpak `com.visualstudio.code`, system install) up to date on this SteamOS PC.

- `systemd/vscode-autoupdate.timer` runs `vscode-autoupdate.service` daily (catching up after sleep/power-off), which
  runs `flatpak update --system --noninteractive -y com.visualstudio.code`. Other Flatpaks are not touched.
- `~/.local/bin/code` is a symlink to `/var/lib/flatpak/exports/bin/com.visualstudio.code`, so `code .` works in a
  terminal.

## Install

```sh
sudo ~/workspace/vscode-autoupdate/install.sh
```

## Check

```sh
systemctl list-timers vscode-autoupdate.timer
journalctl -u vscode-autoupdate.service -n 20
sudo systemctl start vscode-autoupdate.service   # update now
```

## Why this way (2026-10-17)

- The Flatpak build of VS Code can't update itself; only Flatpak can update it.
- A system timer runs whether or not you're in desktop mode. Discover's unattended updates only run in a Plasma session,
  and a user timer can't update a system Flatpak without a password prompt (polkit `auth_admin` outside an active
  session).
- Units are copied into `/etc/systemd/system`, which persists across SteamOS atomic updates.
- Decided by Claude at the user's request ("install vs code that is auto updatable"). Rejected: Discover unattended
  updates (desktop mode only, updates every Flatpak); the `.tar.gz` build (would need its own updater); user timer
  (polkit prompt).

## Status (2026-10-17)

- Done: VS Code 1.139.1 was already installed, with no update pending. `~/.local/bin/code` was added and works.
  The units pass `systemd-analyze verify`.
- Not done yet: the timer isn't installed, because `install.sh` needs sudo and the user's password.
- Test: none yet, besides a manual `flatpak update ... --no-deploy` check ("Nothing to do").
