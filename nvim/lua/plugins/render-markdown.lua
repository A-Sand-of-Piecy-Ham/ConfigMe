return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- or nvim-web-devicons
    ft = { "markdown" },
    opts = {
      heading = {
        sign = false,
        icons = { "   ", "   ", "   ", "   ", "   ", "   " },
      },
      checkbox = {
        enabled = true,
      },
    },
  }
}
