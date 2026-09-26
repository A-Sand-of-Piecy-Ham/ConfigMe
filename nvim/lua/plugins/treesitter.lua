-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

local spec = {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      -- Treesitter highlighting everywhere except LaTeX, where vimtex's own
      -- syntax engine has to stay in charge: its math text objects (i$ / a$)
      -- locate math by vimtex's syntax groups, and those groups do not exist
      -- while treesitter highlights the buffer, so the text objects silently
      -- stop working. vimtex's docs strongly advise this (:h vimtex-faq-treesitter).
      --
      -- The astrocommunity vimtex module tries to do the same through
      -- nvim-treesitter's `highlight.disable`, which AstroNvim v6 no longer
      -- reads -- it is set here because that one is a no-op. The latex parser
      -- is still installed below: snacks.image parses with it to find math to
      -- render, and parsing does not need highlighting to be on.
      highlight = function(lang) return lang ~= "latex" end,
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      -- Merged with what AstroNvim and the imported packs already request, not
      -- replacing it. Listed explicitly rather than left to auto_install so a
      -- fresh machine fetches them up front instead of on first open.
      ensure_installed = {
        -- auto_install fetches a buffer's own language, never the ones
        -- injected into it, so a fresh machine opening an .astro file first
        -- would get no highlighting in its frontmatter or <style> blocks.
        "astro",
        "typescript",
        "tsx",
        "css",
      },
    },
  },
}

-- Optional features (features.md): parsers only a feature needs.
local feature = require("features").on
local parsers = spec.opts.treesitter.ensure_installed
if feature "hardware" then vim.list_extend(parsers, { "systemverilog", "glsl", "wgsl" }) end
if feature "latex" then
  -- latex is parsed for snacks.image math even though vimtex highlights it;
  -- bibtex is highlighted normally.
  vim.list_extend(parsers, { "latex", "bibtex" })
end

---@type LazySpec
return spec
