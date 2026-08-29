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

## Language toolchains

Deliberately not managed here, since each has its own version manager and
pinning them in a dotfiles repo fights those tools:

- Node: `nvm` (`bash/bashrc.linux` sources it)
- Rust: `rustup`
- Python: `uv`
