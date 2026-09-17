if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
      ensure_installed = {
        "lua",
        "vim",
        -- auto_install above covers filetypes Neovim already recognises; these
        -- are listed because the parser name does not match the filetype (a
        -- .sv file is filetype systemverilog but parser "verilog").
        "verilog", -- systemverilog
        "glsl",
        "wgsl",
      },
    },
  },
}
