# ConfigMe

Personal dev environment configuration, symlinked into place by an install
script. Supports macOS, Linux/WSL, and native Windows (Git Bash).

## Includes

- Neovim (AstroNvim v6)
- Bash (per-OS, see below)
- Tmux
- Git
- Ccache
- Ghostty (macOS/Linux) and WezTerm (Windows)
- Claude Code: `CLAUDE.md`, memory, skills

## Install

```bash
./install.sh
```

The script detects the platform and links only what applies. Existing **real**
files are moved to `<name>.bak` first; existing symlinks are replaced silently.

On Windows, run the PowerShell installer from the Windows clone instead:

```powershell
.\install.ps1
```

It runs without elevation. Developer Mode (Settings > System > For developers)
improves the result but is not required -- the script probes for symlink
permission and adapts.

Three mechanisms, chosen per target rather than uniformly:

| Target | Mechanism | Why |
|---|---|---|
| directories (`nvim`, `bash`, `claude/memory`) | junction | Reads identically to a symlink but needs no privilege, so these keep working even if Developer Mode is later turned off. A symlink buys nothing here. |
| `.bashrc`, `.bash_profile`, `.wezterm.lua`, `CLAUDE.md` | symlink, falling back to a shim | Read-only from the consumer's side, so transparency is a pure win, and it drops any dependency on include syntax. |
| `.gitconfig` | `[include]` shim, always | Git writes config by write-and-rename, which would replace a symlink with a regular file and silently strand the mirror. |

Two things worth knowing:

- **`git config --global ...` on Windows appends to the shim**, after the
  `[include]` line, so it overrides the repo value and is not tracked. That is
  correct for machine-local settings, but it is not obvious.
- **Never remove a junction with `Remove-Item -Recurse`.** PowerShell 5.1
  follows the junction and deletes the *target* -- the repo itself. Use
  `(Get-Item x -Force).Delete()` or `fsutil reparsepoint delete`.

Note that PowerShell 5.1's `New-Item -ItemType SymbolicLink` omits the
`ALLOW_UNPRIVILEGED_CREATE` flag that Developer Mode unlocks, so the installer
calls `CreateSymbolicLinkW` directly rather than using it.

## Two checkouts, one source of truth

The WSL checkout at `~/projects/ConfigMe` is the **source of truth**. The
Windows checkout is a **read-only mirror** — never edit it directly.

```
edit in WSL -> commit -> push -> (on Windows) git pull -> .\install.ps1
```

The mirror exists for speed. Symlinking Windows at the ext4 checkout via
`\\wsl.localhost` would give a single source of truth with no sync step, but
every Windows read then crosses the 9p bridge, which costs roughly an order of
magnitude per file operation. Neovim opens dozens of files at startup and
lazy.nvim touches thousands during a sync, so the penalty is obvious in
practice. A native clone also keeps Windows working while the WSL VM is
stopped.

`.gitattributes` pins LF on everything a shell or Neovim reads, so the Windows
clone does not end up with CRLF scripts that bash refuses to execute.

## Bash layout

Bash config is split by platform, because a single file cannot serve Homebrew
on macOS, apt/nvm on WSL, and MinGW on Windows:

| File | Used on |
|---|---|
| `bash/common.sh` | all — PATH, aliases, `EDITOR`, ccache. Linked to `~/.config/dotfiles/common.sh` and sourced by each of the below. |
| `bash/bashrc.darwin`, `bash/bash_profile.darwin` | macOS (Homebrew, Rancher Desktop) |
| `bash/bashrc.linux`, `bash/bash_profile.linux` | Linux and WSL (nvm, cargo, `~/.local/bin`) |
| `bash/bashrc.windows`, `bash/bash_profile.windows` | Git Bash / MSYS2 |

Anything platform-specific belongs in the per-OS file, never in `common.sh`.

## WezTerm

`config.default_prog` drops straight into WSL with tmux. Git Bash, plain WSL,
and PowerShell remain available from the launcher — the tab-bar dropdown, or
`ALT+SHIFT+L`.

## Future considerations

- Ninja
- UV (python)
- nvim LSPs
- Automatic package installation
