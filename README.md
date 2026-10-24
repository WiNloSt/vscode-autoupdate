# vscode-autoupdate

Keeps VS Code (the Flathub Flatpak `com.visualstudio.code`, system install) up to date on Linux, and makes VS Code's
own "Download Update" button run that update (with a "Restart VS Code" button when it's done).

## Who this is for

Any Linux system with systemd where VS Code is installed as the **system** Flathub Flatpak. It was written and tested on
SteamOS (desktop mode, KDE Plasma), but nothing in the problem is SteamOS-specific:

- A Flatpak can't update itself, and VS Code's own updater doesn't exist on Linux: the button only opens
  code.visualstudio.com. That is true on every distribution.
- SteamOS only adds one reason for the choices below: its root filesystem is replaced by atomic updates, so the units
  live in `/etc`, which survives them. On other distributions that is simply the normal place for local units.
- Not tested elsewhere. Untested assumptions: polkit lets an active desktop session update a system Flatpak without a
  password (`org.freedesktop.Flatpak.app-update` is `allow_active=yes` by default), a notification daemon that supports
  actions (KDE does), and `xdg-mime`/`update-desktop-database` being installed. A `--user` Flatpak install needs
  different paths and is not supported.

## What it does

- `systemd/vscode-autoupdate.timer` runs `vscode-autoupdate.service` daily (catching up after sleep/power-off), which
  runs `flatpak update --system --noninteractive -y com.visualstudio.code`. Other Flatpaks are not touched.
- `~/.local/bin/code` is a symlink to `/var/lib/flatpak/exports/bin/com.visualstudio.code`, so `code .` works in a
  terminal.

## Install

```sh
./install.sh   # from a clone of this repo; asks for sudo itself
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
- Done (2026-10-24): VS Code's "Download Update" button runs the Flatpak update. `bin/vscode-patch-product` points
  `downloadUrl` at `vscode-flatpak-update://now`, `bin/vscode-update-now` handles that URL, and
  `vscode-patch-product.path` re-patches after every update. Tested end to end: downgraded to 1.138.0, clicked the
  button, and it updated to 1.139.1 and was re-patched. The button disappears on click (VS Code resets its state to
  idle after opening the link), and shows again after "Check for Updates" until VS Code is restarted.
- Done (2026-10-24): the "VS Code update finished" notification has a "Restart VS Code" button (like the stock
  "Restart to Update"). It sends SIGTERM to the main VS Code processes (hot exit saves unsaved files), waits up to
  30 s, then relaunches, which reopens the previous windows. Tested by the user. Try it without updating:
  `bin/vscode-update-now --offer-restart-only`; `--no-restart-offer` leaves the button out.
- Downgrade to test again: `sudo flatpak update --system -y --commit=<commit> com.visualstudio.code`
  (`flatpak remote-info --log flathub com.visualstudio.code` lists commits).

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
