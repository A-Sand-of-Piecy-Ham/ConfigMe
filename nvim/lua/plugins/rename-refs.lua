-- Hooks lua/rename_refs.lua into astrolsp's rename handling, which both
-- neo-tree and <Leader>R go through. See that file for what it adds.

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  opts = function() require("rename_refs").install() end,
}
