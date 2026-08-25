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

It needs Developer Mode enabled (Settings > System > For developers) or an
elevated prompt, because creating symlinks is a privileged operation otherwise.

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
