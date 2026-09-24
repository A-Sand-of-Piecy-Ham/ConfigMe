# ConfigMe

Personal dev environment configuration, symlinked into place by an install
script. Supports macOS, Linux/WSL, and native Windows (Git Bash).

The install is idempotent, reports what the machine is missing rather than
failing on it, and keeps one checkout authoritative when a machine has two.

## Includes

| Area | What |
|---|---|
| [Neovim](nvim/README.md) | AstroNvim v6, LSP and debugger setup; Python, TypeScript, Astro, C++, Java and LaTeX tooling |
| [Bash](bash/README.md) | Per-OS `bashrc` and `bash_profile` over a shared `common.sh` |
| Terminals | kitty (Linux/WSL), Ghostty (macOS/Linux), WezTerm (Windows) |
| Tmux | `C-Space` prefix, plugins, status bar, nested-session passthrough |
| Git | Config and a global gitignore |
| SSH | Connection multiplexing; host-specific settings stay machine-local |
| Ccache | Compiler cache configuration |
| [Claude Code](claude/README.md) | `CLAUDE.md`, always-loaded rules, and skills |
| `bin/` | Small helpers the configs call -- tmux session attach, kitty/nvim glue, MCP launchers |

## Install

```bash
./install.sh
```

The script detects the platform and links only what applies. Existing **real**
files are moved to `<name>.bak` first; existing symlinks are replaced silently.
It finishes by reporting any missing system packages, so a fresh machine is told
what it lacks without having to ask.

On Windows, run `.\install.ps1` from the Windows clone instead. It needs no
elevation and adapts to whether Developer Mode is on -- see
[docs/windows.md](docs/windows.md) for the link mechanisms it chooses between
and the traps that come with them.

## Checking a machine

```bash
./install.sh --doctor        # report what is missing, change nothing
./install.sh --deps          # list missing packages and print the install line
./install.sh --install-deps  # actually install them (needs sudo)
```

`--doctor` deliberately checks more than whether binaries exist. Most of what
breaks in a setup like this fails *silently*: glyphs render as boxes, images
hang, the terminal quietly drops to software rendering, a language server stops
attaching. So it also verifies terminfo entries, Nerd Font presence, tmux plugin
installation, whether the *running* tmux server has `allow-passthrough` on, and
whether Mesa can reach the d3d12 driver.

It doubles as a guard against stale documentation. Where a config comment
asserts something that could quietly stop being true, `--doctor` checks it.

## Dependencies

`packages/apt.txt` lists every system package with the reason it is needed.
`packages/manual.md` covers what apt cannot provide -- kitty, its terminfo, the
Nerd Font, and `wsl-notify-send.exe`.

## Keybindings

[KEYBINDINGS.md](KEYBINDINGS.md) documents every binding this repo defines, and
the three defaults it deliberately breaks: the tmux prefix (`C-b` ->
`C-Space`), tmux's `last-window` (`l` -> `a`), and kitty's URL opener
(`ctrl+shift+e` -> `ctrl+shift+p o`, because TickTick holds that combination as
a Windows global hotkey).

## Two checkouts, one source of truth

The WSL checkout is the **source of truth**. The Windows checkout is a
**read-only mirror** -- never edit it directly.

```
edit in WSL -> commit -> push -> (on Windows) git pull -> .\install.ps1
```

The mirror exists for speed. Pointing Windows at the ext4 checkout via
`\\wsl.localhost` would give a single source of truth with no sync step, but
every Windows read then crosses the 9p bridge, which costs roughly an order of
magnitude per file operation. Neovim opens dozens of files at startup and
lazy.nvim touches thousands during a sync, so the penalty is obvious in
practice. A native clone also keeps Windows working while the WSL VM is stopped.

`.gitattributes` pins LF on everything a shell or Neovim reads, so the Windows
clone does not end up with CRLF scripts that bash refuses to execute.

## Local overrides

Nothing here assumes it is the only config on the machine. Each area has a
machine-local escape hatch that is not tracked: `~/.ssh/config.local`,
`kitty/local/*.conf`, and `git config --global` writing through an `[include]`
shim. Host names, keys, and anything else specific to one machine belong there
rather than in the repo.
