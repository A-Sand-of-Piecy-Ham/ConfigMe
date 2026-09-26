# Optional features

Each box switches one optional part of this configuration on or off. Ticked is
included; unticked is left out. These are the defaults for every machine.

**Per-machine overrides** go in `~/.config/configme/features.md`, in the same
format. Copy a line from here and change its box; any line present there wins
over this file on that machine only. `./install.sh` creates that file if it is
missing, and `./install.sh --doctor` lists what is on and where each setting
came from.

A feature that is off is left out everywhere: `./install.sh` stops linking its
config, `--deps` and `--install-deps` stop asking for its system packages, the
doctor stops checking for it, Mason stops installing its tools, and its Neovim
plugins are disabled. Switching one off does **not** uninstall or unlink
anything already installed.

After changing a box, restart Neovim and re-run `./install.sh --deps`.

## Languages and editor

- [ ] latex -- LaTeX editing: vimtex (compile, view, motions, conceal), texlab, tex-fmt, latex/bibtex parsers; TeX Live, chktex and zathura from apt (~700 MB)
- [x] java -- Java: jdtls with debugging and test running (nvim-jdtls, java-debug-adapter, java-test) and Spring Boot tools. Needs a JDK 21+, installed separately -- see packages/manual.md
- [x] rust -- Rust: rustaceanvim driving rust-analyzer with clippy, crates.nvim for Cargo.toml. rustup, a stable toolchain and its rust-analyzer, installed by install.sh on Linux
- [x] hardware -- SystemVerilog (verible) and the GLSL and WGSL shader languages: their language servers and treesitter parsers
- [x] diagrams -- Rendered images beyond plain pictures: Mermaid diagrams (mmdc plus a Chrome install), LaTeX math in documents (tectonic), PDF previews (ghostscript). Plain images are always on.

## Applications

Their configs only; the applications themselves install separately -- see
packages/manual.md.

- [x] claude -- Claude Code: CLAUDE.md, the always-loaded rules and the skills, linked into ~/.claude (install.ps1 does the same on Windows)
- [ ] kitty -- kitty's config and CRLF paste filter; on WSL also the hardware-GL launcher, Start Menu entry, kitty/kitten on PATH and Windows toast notifications
- [ ] ghostty -- Ghostty's config (macOS and Linux)
- [ ] wezterm -- WezTerm's config; on WSL it belongs to the Windows side and is linked by install.ps1
