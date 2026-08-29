# Dependencies apt cannot provide

Everything here is installed outside the system package manager, either because
the distro version is too old to be useful or because the thing is not a Linux
package at all. `install.sh --doctor` checks for each of these.

## kitty

Ubuntu 24.04 ships 0.32.2, which is well behind. The graphics protocol is the
reason kitty is here at all, so running a current build matters.

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```

Installs to `~/.local/kitty.app`, no root required. `install.sh` then writes the
launcher wrapper and the desktop entry.

### kitty terminfo

kitty sets `TERM=xterm-kitty` and points `TERMINFO` at its own bundled copy.
That works inside kitty but breaks anything not inheriting that variable --
including a tmux server started from a context without it. Copy it into the
user database so it resolves unconditionally:

```bash
mkdir -p ~/.terminfo && cp -r ~/.local/kitty.app/share/terminfo/* ~/.terminfo/
```

### Start Menu entry (WSL only)

WSLg generates a Windows shortcut for every `.desktop` entry that is
`Terminal=false` and `NoDisplay=false` -- but only from the XDG default data
dirs, `/usr/local/share:/usr/share`. `~/.local/share/applications` is never
scanned. `install.sh` stages the entry and prints this:

```bash
sudo cp ~/.config/kitty/kitty.desktop.staged /usr/share/applications/kitty.desktop
```

## Nerd Font

AstroNvim's statusline and file tree, and the tmux status line, use glyphs no
stock font carries. Without one you get tofu boxes rather than an error.

```bash
curl -fsSLo /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerdFont
unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMonoNerdFont
fc-cache -f
```

`kitty/kitty.conf` asks for `JetBrainsMono NF` by name.

## wsl-notify-send (WSL only)

Produces a real Windows toast rather than a Linux popup floating over the
desktop. kitty's own notification path speaks D-Bus, so `kitty.conf` uses the
`command` action to call this instead; `install.sh` writes that local include
only when the binary is present.

Download `wsl-notify-send_windows_amd64.zip` from
<https://github.com/stuartleeks/wsl-notify-send/releases> and put the `.exe` in
`C:\Users\<you>\AppData\Local\Microsoft\WindowsApps`, which is already on the
Windows PATH and user-writable, so no PATH edit is needed and WSL resolves it
by name.

## tectonic

LaTeX engine used by snacks.image to render math. Not packaged for Ubuntu
24.04. A static binary from the release page is enough:

```bash
curl -fsSL https://github.com/tectonic-typesetting/tectonic/releases/latest \
  | grep -oP 'href="\K[^"]*x86_64-unknown-linux-gnu[^"]*\.tar\.gz' | head -1
# download, tar xzf, then:
install -m755 ./tectonic ~/.local/bin/tectonic
```

The first compile downloads its TeX bundle over the network, so it is slow once
and fast afterwards. No system TeX installation is involved.

## mmdc (mermaid-cli)

Renders Mermaid diagrams for snacks.image. An npm package, not a system one:

```bash
PUPPETEER_SKIP_DOWNLOAD=true npm install -g @mermaid-js/mermaid-cli
```

`PUPPETEER_SKIP_DOWNLOAD` matters. mermaid-cli drives a headless browser
through puppeteer, which by default downloads its own Chromium -- around
150MB, on top of the Chrome already installed here. Skipping it leaves
puppeteer with no browser to find, and it fails at launch rather than falling
back, so `bash/common.sh` exports `PUPPETEER_EXECUTABLE_PATH` pointing at the
system Chrome. Without that variable `mmdc` errors out; with it, it works
with no further configuration.

Note that npm's global prefix here is inside the nvm-managed node
(`~/.nvm/versions/node/<version>`), so `mmdc` disappears if you switch node
versions with nvm and has to be reinstalled for the new one.

## tmux plugins

`tpm` is cloned by `install.sh`. The plugins themselves are not:

```
prefix + I
```

The prefix is `C-Space`. Until this runs, `tmux-resurrect` and
`tmux-continuum` are inert config -- session restore silently does nothing.

## Claude Code MCP servers

Registered in `~/.claude.json`, which cannot be symlinked into this repo: it
also holds per-project session state that changes constantly. Recorded here so
the set is reproducible on a new machine.

Currently registered: `filesystem`, `context7`, `sequential-thinking`,
`chrome-devtools`, `github`.

`fetch` and `memory` were removed. `fetch` duplicated the built-in `WebFetch`,
which is strictly better -- it takes a prompt and answers against the content
rather than returning the whole page -- and it launched through `uvx`, spinning
a Python environment per call. `memory` had never written a store file, and its
ground is covered by auto memory and `claude/rules/`.

### github

```bash
claude mcp add github -s user -- ~/.local/bin/github-mcp
```

`bin/github-mcp` reads `gh auth token` at launch rather than storing a
Personal Access Token in `~/.claude.json`. The documented alternatives are a
PAT pasted into config, or Docker -- which is unusable here while the engine
returns 500s from a CLI/engine version mismatch. Reading from `gh` also means
the credential rotates when `gh` refreshes, and revoking `gh` revokes this.

That token carries `repo` scope, so the server can write to repositories. The
never-push-without-asking rule binds it exactly as it binds `git`.

### chrome-devtools

```bash
claude mcp add chrome-devtools -s user -- npx -y chrome-devtools-mcp@latest \
  --executablePath /usr/bin/google-chrome \
  --isolated \
  --usageStatistics false
```

Three flags worth explaining:

- `--executablePath` for the same reason mermaid-cli needs
  `PUPPETEER_EXECUTABLE_PATH`: the server drives Chrome through puppeteer, and
  pointing it at the installed browser avoids a redundant download.
- `--isolated` uses a temporary profile that is cleaned up afterwards, so an
  agent driving the browser never touches the real Chrome profile, its cookies
  or its logged-in sessions.
- `--usageStatistics false` opts out of Google's usage collection, which is
  on by default.

Note that performance tools still send trace URLs to the Google CrUX API to
fetch field data. Add `--no-performance-crux` to stop that; the cost is losing
real-user performance comparisons.

### Why playwright was removed

The playwright MCP server was registered alongside this one and was almost
entirely redundant: 20 of its 24 tools had a direct chrome-devtools
equivalent, covering the whole interaction and inspection surface. What
chrome-devtools adds -- `performance_start_trace`, `performance_stop_trace`,
`performance_analyze_insight`, `lighthouse_audit`, `take_heapsnapshot` and
`emulate` -- playwright had no counterpart for, making chrome-devtools close
to a superset.

It was also pointed at `PLAYWRIGHT_MCP_CDP_ENDPOINT=http://localhost:9222`,
which expects a Chrome already running with remote debugging on that port.
Nothing listens there by default, so it only worked when such a Chrome had
been started by hand.

Note that the playwright MCP *server* is unrelated to the playwright npm
*library*. Removing the server does not affect any project's tests; a project
that tests with Playwright depends on the library and is unaffected.

The one real capability lost is non-Chrome browsers: playwright can drive
Firefox and WebKit, chrome-devtools is Chrome-only. If Firefox coverage
becomes necessary, re-adding is one command:

```bash
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
```

Note the omitted CDP endpoint -- without it the server launches its own
browser rather than requiring one on port 9222.

## Language toolchains

Deliberately not managed here, since each has its own version manager and
pinning them in a dotfiles repo fights those tools:

- Node: `nvm` (`bash/bashrc.linux` sources it)
- Rust: `rustup`
- Python: `uv`
