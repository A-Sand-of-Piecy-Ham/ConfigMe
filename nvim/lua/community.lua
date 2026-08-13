-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- Harpoon 2 is configured entirely in plugins/harpoon.lua instead — this
  -- pack's <C-x>/<C-p>/<C-n> bindings hijacked builtin decrement/completion
  -- keys, its terminal-goto used harpoon.term (removed in harpoon2, always
  -- errored), and it duplicated the add/menu bindings we already have.
  -- import/override with your plugins folder
  -- Install your specific language adapter pack
  { import = "astrocommunity.pack.cpp" }, -- Configures CodeLLDB for C/C++
  { import = "astrocommunity.pack.rust" }, -- Alternative for Rust
}
