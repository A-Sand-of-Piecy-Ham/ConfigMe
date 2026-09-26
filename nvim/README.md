# Neovim Config

AstroNvim v6+ template with personal customizations. Base: [AstroNvim](https://github.com/AstroNvim/AstroNvim).

## Installation

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
# clone via dotfiles install.sh — do not clone directly
bash ~/projects/dotfiles/install.sh
```

## Customizations

### Community Packs (`lua/community.lua`)

| Pack | Purpose |
|------|---------|
| `astrocommunity.pack.lua` | Lua LSP + tooling |
| `astrocommunity.pack.cpp` | clangd + codelldb for C/C++ |
| `astrocommunity.pack.rust` | Rust: rustaceanvim (drives rust-analyzer), codelldb, crates.nvim -- see Rust below |
| `astrocommunity.markdown-and-latex.vimtex` | vimtex, plus which-key descriptions for its maps |

Harpoon is deliberately *not* imported from its community module; it is
configured entirely in `lua/plugins/harpoon.lua`. Neither is `pack.astro` --
see Astro below.

### Mason Tool Installer (`lua/plugins/mason.lua`)

Declarative list of tools Mason keeps installed across machines — avoids manual `:MasonInstall` after setup.

Notable entries: `clangd`, `codelldb`, `cpptools`, `jdtls`, `java-debug-adapter`, `typescript-language-server`.

### Python LSP (`lua/plugins/astrolsp.lua`)

Python buffers attach **ty** (Astral, Rust) for type checking and language
intelligence, plus **ruff** for lint and formatting. They are designed to pair:
ty delegates formatting to ruff rather than duplicating it.

**basedpyright is installed but does not attach.** It is the stricter checker
and ty is pre-1.0, so it is kept as an on-demand second opinion via
`:LspStart basedpyright`. It is disabled through a `false` handler in
astrolsp's `handlers` table, the same mechanism used for jdtls.

The reason it does not attach by default is cost: basedpyright is pyright, which
is TypeScript, and ships a bundled Node runtime. It is the largest language
server in this configuration by a wide margin. ty is a single Rust binary.

`./install.sh --doctor` verifies both halves of this arrangement, because the
arrangement is what the comments in `astrolsp.lua` describe and comments cannot
check themselves.

### File renames (`lua/rename_refs.lua`)

Renaming or moving a file -- in neo-tree, or the current buffer's with
`<Leader>R` -- rewrites whatever referenced it, in two ways:

- **Language servers**, through AstroNvim. astrolsp sends
  `workspace/willRenameFiles` before the move, honouring each server's declared
  file filters, with a 10s timeout. This is AstroNvim's own wiring, not this
  config's. It updates JS/TS imports, Lua, Rust, and whatever else a running
  server implements.
- **HTML and CSS references**, through `lua/rename_refs.lua`. No HTML or CSS
  server implements the request -- VS Code's own do not either -- so this
  rewrites `src`, `href`, `poster`, `srcset`, `url()` and `@import` itself,
  after the move. It handles relative paths, root-relative paths (resolved from
  the git root), folder renames, a moved file's own outgoing references, and
  keeps `?query` / `#fragment` and `%20`-style encoding intact.

Every file either one rewrote is **left unsaved** and listed in one
notification, since many will be buffers that are not on screen. Review, then
`:wa`.

`rename_refs.lua` works by wrapping astrolsp's `willRenameFiles` /
`didRenameFiles` rather than listening to neo-tree itself; an earlier version
of this config did the latter and sent every server the request twice.

Limits:

- **Only running servers answer**, and a server only updates files it knows
  about. For JavaScript that means a `jsconfig.json` or `tsconfig.json`;
  without one, tsserver sees only open files and their imports. A server that
  times out is skipped silently -- astrolsp does not report it.
- **The HTML/CSS updater only rewrites what it can resolve with confidence.**
  URLs with a scheme, template syntax (`{{`, `${`), and references to files
  that do not exist -- such as an `href` that is really a route -- are left as
  written. Paths assembled at runtime in JS cannot be seen at all, and Vite
  `public/` assets written as `/logo.png` do not resolve from the git root, so
  they are missed rather than mis-rewritten.

To follow an `href` or `src` to its file, use `gf`. The HTML server exposes
those paths as document links, which Neovim does not wire to `gd`.

### LaTeX (`lua/plugins/vimtex.lua`)

Three pieces with separate jobs. **vimtex** compiles with latexmk, views in
zathura with synctex in both directions, and provides the LaTeX motions and
text objects. **texlab** provides language features: completion for `\ref`,
`\cite` and labels, and chktex lint as diagnostics. **tex-fmt** formats,
invoked through texlab. texlab's own build and forward-search settings are left
unset so it does not duplicate vimtex. Keys are in
[KEYBINDINGS.md](../KEYBINDINGS.md#latex-vimtex).

Documents compile with TeX Live's pdfLaTeX (see `packages/apt.txt`), because
that is what Overleaf, arXiv and the IEEE/ACM templates target. tectonic is
still installed, but only for snacks.image's inline math.

Two settings exist to route around quiet failures:

- **Treesitter highlighting is off for LaTeX.** vimtex's math text objects find
  math through vimtex's own syntax groups, which do not exist while treesitter
  highlights the buffer, so `i$` / `a$` silently stop working. The community
  module tries to disable it through an option AstroNvim v6 no longer reads, so
  it is done in `lua/plugins/treesitter.lua` instead. The parser is still
  installed; snacks.image parses with it.
- **`tex_flavor = "latex"`.** Otherwise a file without `\documentclass`, such
  as a chapter pulled in with `\input`, is detected as `plaintex` and vimtex
  does not load for it.

Markup is concealed into what it typesets to -- `\delta` shows as δ, `\leq`
as ≤, `x_1^2` as x₁² -- through vimtex's conceal support, enabled by
`after/ftplugin/tex.lua` at level 1, so markup with no replacement character,
such as the `$` delimiters, still leaves a space. The cursor line always shows
the raw source.

The viewer is vimtex's `zathura_simple`, not `zathura`: the latter finds its
window with xdotool, which cannot see the Wayland clients that WSLg and
current Raspberry Pi OS produce.

### Astro

The language server and treesitter parsers are added directly, not through
`astrocommunity.pack.astro`. That pack imports `pack.typescript`, which
installs vtsls and runs it alongside `ts_ls` -- see Future considerations for
why vtsls is absent. When a project has no TypeScript of its own, the server
falls back to the copy bundled with astro-language-server; mason-lspconfig
handles that, so there is nothing to configure here.

### Rust (`lua/plugins/rust.lua`)

Comes almost entirely from `astrocommunity.pack.rust`: rustaceanvim runs
rust-analyzer (from Mason) and adds the `:RustLsp` commands, codelldb handles
debugging, and crates.nvim adds version completion and hover in `Cargo.toml`.
Formatting is rustfmt through `<Leader>lf`. The toolchain itself comes from
rustup -- see `packages/manual.md` for the components rust-analyzer depends on.

`lua/plugins/rust.lua` exists for one fix. The pack configures clippy as the
checker but the setting never reached rust-analyzer: the pack snapshots its
LSP config when rustaceanvim loads, before astrolsp has registered that
setting, and it also switches off rustaceanvim's own clippy default. The result
was plain `cargo check` with no clippy lints and no sign anything was missing.
Re-enabling rustaceanvim's default restores clippy at server start.

Useful `:RustLsp` subcommands: `runnables` and `testables` (pick and run),
`debuggables` (same, under codelldb), `expandMacro`, `explainError`,
`renderDiagnostic` (the full rustc output), `openCargo`, `openDocs`, and
`hover actions` (hover with runnable actions such as "Run" or "Go to impl").

### Future considerations

Deliberate deferrals, recorded so they are not rediscovered from scratch.

Each entry is stamped with what it was true of. These are claims about
third-party software that moves independently of this repo, so treat a stamp
older than the version you have installed as unverified rather than as fact --
re-check before acting on it.

- **`veridian` for SystemVerilog** *(as of verible 0.0-3946, 2026-09)*.
  `verible` is installed and covers formatting and linting well, but its
  semantic analysis is thin -- no go-to-definition or cross-module completion.
  `veridian` provides those. It is not packaged in Mason and needs a manual Rust
  build plus an `install.sh` dependency entry, so it is deferred until there is
  a hardware project to justify it.

- **`tsgo` (TypeScript 7, Go-native)** *(as of TypeScript 7.0 RC, 2026-09)*.
  Would eliminate the Node/V8 language server entirely. At the time of writing
  the language *service* is not at parity with `tsc`, and there is an open
  upstream report of runaway memory under Neovim specifically, so `ts_ls`
  remains primary.

- **`vtsls` is intentionally absent** *(as of mason-registry 2026-08-28)*. Its
  Mason `bin` entry is a symlink to an npm `sh` shim that derives `basedir` from
  `$0` without dereferencing the symlink, so it resolved to `mason/@vtsls/...`
  and died with MODULE_NOT_FOUND on every start. `typescript-language-server`
  ships the real JS file in `.bin` and is unaffected. This is a packaging bug,
  so it may simply be fixed upstream.

- **Automatic type acquisition stays enabled, deliberately** *(decided
  2026-09)*. It keeps a persistent `typingsInstaller` process alive, on the
  order of 100 MB. Disabling it was considered and rejected: the saving is
  negligible against available memory, and JavaScript support is kept at full
  strength regardless of how little hand-written JavaScript happens to be
  checked in at any moment. ATA benefits plain JavaScript using third-party
  libraries that ship no types; browser and DOM APIs come from TypeScript's own
  `lib.dom.d.ts` and are unaffected either way.

### DAP / Debugging (`lua/plugins/dap-attach.lua`)

Custom DAP behavior on top of the cpp community pack:

- **`lldb` adapter alias** — registers `dap.adapters.lldb = dap.adapters.codelldb` so `.vscode/launch.json` files using `"type": "lldb"` (VS Code's CodeLLDB naming) work in nvim-dap without modification.

- **Walk provider** — `dap.providers.configs["dap.vscode.walk"]` walks up from the current buffer's directory to find the nearest `.vscode/launch.json` that isn't already covered by the built-in cwd provider. Configs found this way are prefixed `[repo]`. Handles `${command:pickProcess}` replacement (see below).

- **Global config dedup + prefix** — on startup, existing `dap.configurations` entries are deduplicated by name and prefixed `[global]` to distinguish them from repo-local configs.

- **Custom process picker** — overrides `dap.utils.pick_process` with a Telescope picker that displays full process argument strings (not just PIDs), enabling fuzzy search by process name or arguments. Applied to both the global "Attach to running process" config and any `[repo]` config that uses `${command:pickProcess}`.

- **Breakpoint persistence** — breakpoints are saved to `~/.local/share/nvim/dap_breakpoints_<hash>.json` on exit and restored on startup, scoped per working directory.

### LSP (`lua/plugins/astrolsp.lua`)

- `format_on_save` disabled globally and explicitly for clangd (avoids unwanted reformatting on save).
- `<Leader>lR` and `gr` both open Telescope references with wider filename display.
- `gD` bound to LSP declaration.
- Inlay hints off by default.

### Harpoon (`lua/plugins/harpoon.lua`)

Harpoon2 with custom keybinds (overrides the community pack defaults):

| Key | Action |
|-----|--------|
| `<Leader>ha` | Add current file |
| `<Leader>hm` | Toggle quick menu |
| `<Leader>h1`–`h4` | Jump to slot 1–4 |
| `<Leader>hs` | Telescope search across marked files |

### Editor Options (`lua/plugins/astrocore.lua`)

- Relative line numbers on
- Autopairs disabled
- Diagnostics: virtual text on, virtual lines off
- No format on save (defer to explicit `:Format`)

