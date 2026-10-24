
## 2026-10-24: 48 extensions had registry entries but no folder
- Symptom: "Unable to read file .../package.json" in the Extensions view (azure-repos first, then 47 more).
- Cause: `extensions.json` listed them, folders gone (most surviving folders dated 2026-10-17, the wipe day). Not the updater.
- Fix: pruned the dead entries from `extensions.json`, then `flatpak run com.visualstudio.code --install-extension <id>…`
  from bash (zsh doesn't word-split an unquoted `$args`). Backup of the old registry was in the session scratchpad.
