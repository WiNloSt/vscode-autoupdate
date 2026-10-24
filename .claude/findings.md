
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
