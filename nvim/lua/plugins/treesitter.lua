-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      -- Merged with what AstroNvim and the imported packs already request, not
      -- replacing it. Listed explicitly rather than left to auto_install so a
      -- fresh machine fetches them up front instead of on first open.
      ensure_installed = {
        "systemverilog",
        "glsl",
        "wgsl",
      },
    },
  },
}
