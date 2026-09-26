-- Rust support comes from astrocommunity.pack.rust (see community.lua):
-- rustaceanvim driving rust-analyzer, codelldb debugging, crates.nvim for
-- Cargo.toml. This file corrects one thing in it and picks where
-- rust-analyzer comes from.
--
-- The pack sets clippy as rust-analyzer's checker, but the setting never
-- reached the server. The pack snapshots vim.lsp.config["rust_analyzer"] when
-- rustaceanvim loads, which happens before astrolsp registers its settings, so
-- the snapshot has no `check` and rust-analyzer silently fell back to plain
-- `cargo check` -- no clippy lints, ever. The pack also switches off
-- rustaceanvim's own clippy default, expecting its setting to cover it.
--
-- Switching that default back on restores clippy through rustaceanvim itself,
-- evaluated when the server starts rather than from the stale snapshot. It
-- applies only when no `check` is configured and cargo-clippy is installed, so
-- it cannot conflict once the pack is fixed upstream.

-- Optional feature (features.md). Both of the pack's plugins are declared
-- here with `enabled`, so while rust is off -- and the pack itself is
-- skipped -- lazy still knows them and keeps their lazy-lock.json pins.
local rust = require("features").on "rust"

-- rust-analyzer from the project's own toolchain, through rustup, with Mason's
-- build as the fallback.
--
-- Mason ships the newest rust-analyzer, and that refuses any toolchain more
-- than a few releases old ("only supports 1.94.0 and higher"). Upgrading
-- stable does not help a project that pins an older toolchain in
-- rust-toolchain.toml. rustup's rust-analyzer component always matches the
-- toolchain it belongs to, and `rustup which` resolves per directory, pins
-- included. A toolchain without the component gets it added on first use;
-- offline, that add fails after about 30 s (retries off -- rustup's default
-- three retries stretch it to two minutes) and Mason's build starts instead.
--
-- rustaceanvim evaluates `cmd` with no project root and the server inherits
-- Neovim's cwd, so the launcher cds to the buffer's directory itself -- that
-- is what makes rustup see the pin. One server serves every workspace added
-- to it later, so a second project on a different toolchain opened in the
-- same session is analysed by the first one's rust-analyzer.
--
-- Everything the launcher prints goes to stderr (the LSP log): stdout is the
-- protocol channel.
local LAUNCHER = [[
cd "$1" 2>/dev/null
ra=$(rustup which rust-analyzer 2>/dev/null) \
  || { RUSTUP_MAX_RETRIES=0 rustup component add rust-analyzer >&2 && ra=$(rustup which rust-analyzer); } \
  || ra=$2
shift 2
exec "$ra" "$@"
]]

local function server_cmd()
  -- Mason's bin directory is first on Neovim's PATH, so this is its build.
  local mason = vim.fn.exepath "rust-analyzer"
  local logfile = require("rustaceanvim.config.internal").server.logfile
  if vim.fn.executable "rustup" == 0 then return { mason, "--log-file", logfile } end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  return { "sh", "-c", LAUNCHER, "sh", dir, mason ~= "" and mason or "rust-analyzer", "--log-file", logfile }
end

---@type LazySpec
return {
  { "Saecki/crates.nvim", enabled = rust },
  {
    "mrcjkb/rustaceanvim",
    enabled = rust,
    opts = function(_, opts)
      opts.tools = vim.tbl_extend("force", opts.tools or {}, { enable_clippy = true })
      opts.server = vim.tbl_extend("force", opts.server or {}, { cmd = server_cmd })
    end,
  },
}
