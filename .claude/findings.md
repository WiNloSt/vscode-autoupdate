
## 2026-10-24: 48 extensions had registry entries but no folder
- Symptom: "Unable to read file .../package.json" in the Extensions view (azure-repos first, then 47 more).
- Cause: `extensions.json` listed them, folders gone (most surviving folders dated 2026-10-17, the wipe day). Not the updater.
- Fix: pruned the dead entries from `extensions.json`, then `flatpak run com.visualstudio.code --install-extension <id>…`
  from bash (zsh doesn't word-split an unquoted `$args`). Backup of the old registry was in the session scratchpad.

## 2026-10-24: update button hook, built but not installed yet
- Probe passed: from inside the Flatpak sandbox, the OpenURI portal handed `vscode-flatpak-update://now` to a host
  `.desktop` handler with no "open with" prompt.
- Built: `bin/vscode-update-now` (click handler, runs the user-level `flatpak update`), `bin/vscode-patch-product`
  (root; swaps `downloadUrl` in product.json), `systemd/vscode-patch-product.path` (re-patches whenever the
  `.../x86_64/stable` folder changes, i.e. after each update), and install.sh steps for all of it.
- Not done: `./install.sh` was denied by the auto-mode classifier ("unauthorized persistence"); the user must run it.
- Untested: the real button click, and that VS Code accepts a patched product.json without an "installation corrupt" warning.

## 2026-10-24: update button hook installed and tested
- install.sh run by the user; button click verified: downgraded to 1.138.0 (commit 10a010f7), VS Code showed "Download
  Update", click ran `vscode-update-now`, updated to 1.139.1, and the path unit re-patched product.json by itself.
- No "installation corrupt" warning in the VS Code log with the patched product.json.
- Quirk: the button disappears right after the click (VS Code resets to idle on Linux); "Check for Updates" shows it
  again until VS Code restarts. Progress is only visible via the notify-send notifications.

## 2026-10-24: restart button on the finished notification, tested by the user
- `notify-send -A` (libnotify 0.8.8) gives "Restart VS Code" / "Later"; a click runs SIGTERM on the main processes
  (`/app/extra/vscode/code` without `--type=`, not running a script under `/app/` or the extensions folder), then
  `flatpak run com.visualstudio.code`. The user clicked it and VS Code came back on 1.139.1.
- Decision (user, 2026-10-24: "just like the normal update"): behave like stock VS Code's restart-to-update. No test
  script yet; the manual `--offer-restart-only` flag is the check.

## 2026-10-24: audit before making the repo public
- Secrets: `gitleaks git` and `gitleaks dir` clean (10 commits); manual grep for tokens/keys/passwords found none.
- In the tree: no email, real name or home path. `install.sh` no longer defaults the user to `deck`.
- In git history (not rewritten): author name and email on all commits, and a `Claude-Session:` URL trailer on
  every commit. Both are public once pushed; decision pending with the user.
- README now says the repo applies to any systemd Linux with the system Flathub Flatpak, not only SteamOS.
