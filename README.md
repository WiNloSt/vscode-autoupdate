# vscode-autoupdate

Keeps VS Code (the Flathub Flatpak `com.visualstudio.code`, system install) up to date on this SteamOS PC.

- `systemd/vscode-autoupdate.timer` runs `vscode-autoupdate.service` daily (catching up after sleep/power-off), which
  runs `flatpak update --system --noninteractive -y com.visualstudio.code`. Other Flatpaks are not touched.
- `~/.local/bin/code` is a symlink to `/var/lib/flatpak/exports/bin/com.visualstudio.code`, so `code .` works in a
  terminal.

## Install

```sh
~/workspace/vscode-autoupdate/install.sh   # asks for sudo itself
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

## Status (2026-10-19)

- Done: VS Code 1.139.1 was already installed, with no update pending. `~/.local/bin/code` was added and works.
  The units pass `systemd-analyze verify`.
- Done: the timer is installed (2026-10-19: `systemctl list-timers` shows it, next run 2026-10-20 00:07 +07).
- Test: none yet, besides a manual `flatpak update ... --no-deploy` check ("Nothing to do").
- Next (proposed, not built): make VS Code's own "Download Update" button run the Flatpak update instead of opening
  the website. See the findings below.

## Findings: hooking the update button (2026-10-19)

- On Linux the button only calls `openExternal(product.downloadUrl)` (checked in 1.139.1's `out/main.js`,
  `doDownloadUpdate`); `downloadUrl` is `https://code.visualstudio.com` in `product.json`. Electron's `autoUpdater`
  has no Linux support, so there is no built-in self-update to switch on.
- Idea (user, 2026-10-19): point `downloadUrl` at a custom scheme handled by our script, and re-patch `product.json`
  after every update ("the update scripts has to keep updating product.json").
- `product.json` is at `/var/lib/flatpak/app/com.visualstudio.code/current/active/files/extra/vscode/resources/app/`,
  root-owned, link count 1: it's extra-data, not hard-linked into the ostree repo, so editing it doesn't corrupt the
  repo. Each update deploys a new commit folder, which drops the patch.
- polkit `org.freedesktop.Flatpak.app-update` is `allow_active=yes`: a click-triggered update from the desktop session
  needs no password. The sandbox can talk to `org.freedesktop.Flatpak` (`host-spawn` is bundled).
- VS Code's update check asks Microsoft's server, so the button can appear before Flathub has the version.
- Unknown yet: whether `openExternal` inside the Flatpak (via the OpenURI portal) hands a custom scheme to a host
  handler, and whether the portal asks "open with" first.
