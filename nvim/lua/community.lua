-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- Import Harpoon 2 from the community repository
  { import = "astrocommunity.motion.harpoon" },
  -- import/override with your plugins folder
  -- Install your specific language adapter pack
  { import = "astrocommunity.pack.cpp" }, -- Configures CodeLLDB for C/C++
  { import = "astrocommunity.pack.rust" }, -- Alternative for Rust
}
