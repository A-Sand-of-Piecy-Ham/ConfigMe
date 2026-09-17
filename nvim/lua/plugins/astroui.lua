-- Reduced from the AstroNvim template, which shipped this file stubbed out with
-- `if true then return {} end`. Everything else in it was example scaffolding:
-- two empty highlight-override tables and a braille LSP-loading spinner.
--
-- The colorscheme is AstroNvim's default too, so this changes nothing at
-- runtime. It is kept to state the choice rather than inherit it, so a future
-- default change is visible as a diff instead of a surprise.
---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "astrodark",
  },
}
