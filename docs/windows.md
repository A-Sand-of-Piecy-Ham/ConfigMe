# Windows install

Run the PowerShell installer from the Windows clone:

```powershell
.\install.ps1
```

It runs without elevation. Developer Mode (Settings > System > For developers)
improves the result but is not required -- the script probes for symlink
permission and adapts.

## Three link mechanisms

Chosen per target rather than uniformly:

| Target | Mechanism | Why |
|---|---|---|
| directories (`nvim`, `bash`) | junction | Reads identically to a symlink but needs no privilege, so these keep working even if Developer Mode is later turned off. A symlink buys nothing here. |
| `.bashrc`, `.bash_profile`, `.wezterm.lua`, `CLAUDE.md` | symlink, falling back to a shim | Read-only from the consumer's side, so transparency is a pure win, and it drops any dependency on include syntax. |
| `.gitconfig` | `[include]` shim, always | Git writes config by write-and-rename, which would replace a symlink with a regular file and silently strand the mirror. |

## Traps

- **`git config --global ...` appends to the shim**, after the `[include]` line,
  so it overrides the repo value and is not tracked. That is correct for
  machine-local settings, but it is not obvious.

- **Never remove a junction with `Remove-Item -Recurse`.** PowerShell 5.1
  follows the junction and deletes the *target* -- the repo itself. Use
  `(Get-Item x -Force).Delete()` or `fsutil reparsepoint delete`.

- **`install.ps1` must stay pure ASCII.** PowerShell 5.1 decodes a `-File`
  script as Windows-1252, so a UTF-8 em dash arrives as a smart quote and the
  script fails to parse.

## Why the installer calls CreateSymbolicLinkW

PowerShell 5.1's `New-Item -ItemType SymbolicLink` omits the
`ALLOW_UNPRIVILEGED_CREATE` flag that Developer Mode unlocks, so it reports a
privilege error on a machine that in fact has the privilege. The installer
P/Invokes `CreateSymbolicLinkW` directly instead.

## Two checkouts

The WSL checkout is the source of truth and the Windows checkout is a read-only
mirror -- see the main [README](../README.md#two-checkouts-one-source-of-truth)
for why, and for the sync flow.
