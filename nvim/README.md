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
| `astrocommunity.motion.harpoon` | Harpoon2 base (overridden below) |
| `astrocommunity.pack.cpp` | clangd + codelldb for C/C++ |
| `astrocommunity.pack.rust` | rust-analyzer + codelldb for Rust |

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

### File renames (`lua/plugins/neo-tree.lua`)

Renaming or moving a file in neo-tree sends `workspace/willRenameFiles` to the
attached language servers, so imports and references are rewritten rather than
silently broken. Neovim does not do this on its own -- the request has to come
from whatever performed the rename, and while snacks.nvim implements the client
half, nothing subscribes it to neo-tree's events by default.

Servers that do not implement the request simply do not answer it, so this is
safe regardless of which are attached.

#### Future considerations

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

