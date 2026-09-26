-- Rust support comes from astrocommunity.pack.rust (see community.lua):
-- rustaceanvim driving rust-analyzer, codelldb debugging, crates.nvim for
-- Cargo.toml. This file corrects one thing in it.
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

---@type LazySpec
return {
  { "Saecki/crates.nvim", enabled = rust },
  {
    "mrcjkb/rustaceanvim",
    enabled = rust,
    opts = function(_, opts)
      opts.tools = vim.tbl_extend("force", opts.tools or {}, { enable_clippy = true })
    end,
  },
}
