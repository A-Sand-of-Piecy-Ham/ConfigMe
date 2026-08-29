# Keybindings

Every binding this repo defines or deliberately breaks. Generated from the
configs themselves, not from memory -- if something here disagrees with
behaviour, the config is right and this file is stale.

## Changed from defaults

These three will surprise you, because the default still exists in your muscle
memory and in every tutorial online.

| Was | Now | Why |
|---|---|---|
| tmux prefix `C-b` | **`C-Space`** | `C-b` is vim's page-up, felt both in nvim and in tmux's own vi copy-mode. `C-Space` also avoids readline's `C-a`. |
| tmux `prefix l` — last-window | **`prefix a`** | `l` became "select pane right" in the vi-style navigation set. Not moved to `Tab`: tmux-sidebar claims that, and plugin bindings load last and win. |
| kitty `ctrl+shift+e` — open URL | **`ctrl+shift+p` `o`** | TickTick registers `ctrl+shift+e` as a Windows global hotkey. A global hotkey is intercepted by the OS before the focused window sees it, so kitty could never receive the combination -- the binding would look present and silently never fire. |

## tmux

Prefix is **`C-Space`**. Notation below omits it: "`a`" means `C-Space` then `a`.

### Panes and windows

| Key | Action |
|---|---|
| `h` `j` `k` `l` | Select pane left/down/up/right (repeatable) |
| `H` `J` `K` `L` | Resize pane by 5 (repeatable) |
| `\|` | Split horizontally, in the current directory |
| `-` | Split vertically, in the current directory |
| `c` | New window, in the current directory |
| `a` | Last window |

Splits and new windows inherit the current pane's directory rather than the
directory the session was created in.

### Sessions and config

| Key | Action |
|---|---|
| `s` | Session switcher through fzf, in a popup |
| `S` | `choose-tree` — tmux's built-in picker |
| `C-p` | Scratch shell popup, in the current directory |
| `R` | Reload `~/.tmux.conf` |

`R` matters more than it looks: a running tmux server never re-reads its config
on its own, so editing the repo file changes nothing in an existing session
until this runs. `tmux-autoreload` would cover it, but it watches
`~/.tmux.conf`, which is a symlink into this repo, so writes to the target go
unnoticed -- and it needs `entr` installed to do anything at all.

`s` needs `fzf`. `S` always works if it is missing.

### Copy mode

vi keys. Enter with `[`.

| Key | Action |
|---|---|
| `v` | Begin selection |
| `y` | Copy selection and exit |
| `C-v` | Toggle rectangle select |
| `Escape` | Cancel (by default only `q` and `C-c` do) |

Copied text reaches the Windows clipboard because `set-clipboard` is `on`.
tmux's default is `external`, which sounds permissive but means the opposite:
tmux sets the terminal clipboard itself while *ignoring* OSC 52 from
applications inside it, so nvim's `"+y` never gets out.

### Owned by plugins

Not defined here, but they will collide with anything you add:

| Key | Plugin |
|---|---|
| `Tab`, `BSpace` | tmux-sidebar |
| `Enter`, `\` | tmux-menus |
| `F` | tmux-fzf |
| `C-s`, `C-r` | tmux-resurrect (save / restore) |
| `I`, `U`, `M-u` | tpm (install / update / uninstall plugins) |

`prefix I` is the one to remember: plugins are not installed until it runs.

## kitty

Hints put a letter on every match on screen; type the letter to pick it.

| Key | Action |
|---|---|
| `ctrl+shift+p` `o` | Open a URL |
| `ctrl+shift+p` `n` | **Open `file:line` in nvim** |
| `ctrl+shift+p` `y` | Copy a path |
| `ctrl+shift+p` `h` | Copy a git hash |
| `ctrl+shift+p` `l` | Copy a line |
| `ctrl+shift+p` `w` | Copy a word |
| `ctrl+shift+p` `u` | Copy a URL |
| `ctrl+shift+p` `f` | Insert a path at the cursor *(kitty default)* |
| `ctrl+shift+u` | Unicode input *(kitty default)* |

`ctrl+shift+p` `n` is the one worth learning: run a build, press it, pick the
error, and the file opens at that line.

It opens through `bin/kitty-nvim` rather than nvim directly. kitty launches the
editor without a shell, so nvim would appear in a bare kitty window beside the
one already running tmux, splitting the workspace in two. The script routes
into the running tmux session instead.

URLs open in the Windows default browser via `wslview`.

## WezTerm

Still installed on the Windows side for Git Bash and PowerShell, though nvim
now runs under kitty.

| Key | Action |
|---|---|
| `ALT+SHIFT+L` | Launcher — WSL+tmux, WSL, Git Bash, PowerShell |

## Neovim

Leader is `<Space>`. Only what this repo defines; AstroNvim's own mappings are
documented upstream.

| Key | Action |
|---|---|
| `<Leader><Leader>a` | Harpoon: add file |
| `<Leader><Leader>m` | Harpoon: toggle menu |
| `<Leader><Leader>1`..`4` | Harpoon: jump to slot |
| `<Leader><Leader>s` | Harpoon: search with Telescope |
| `<Leader>us` | Toggle spellcheck (starts and stops `harper_ls`) |
| `<Leader>lR` | LSP references in Telescope |
| `<Leader>gv` | Diffview (which-key group) |

## Shell aliases

Not keybindings, but the other half of the kitten setup. Defined in
`bash/common.sh`, guarded on `kitten` being present.

| Command | Does |
|---|---|
| `icat FILE` | Render an image in the terminal |
| `hgrep PATTERN` | ripgrep with clickable OSC 8 hyperlinks |
| `kdiff A B` | Side-by-side diff; renders changed images |
| `... \| clip` | System clipboard; works over SSH |
| `ssh HOST` | `kitten ssh` — carries kitty's terminfo to the remote host |
| `git kdiff` | The diff kitten as a git difftool |

`ssh` is only shadowed when `TERM=xterm-kitty`, so it behaves normally
elsewhere.
