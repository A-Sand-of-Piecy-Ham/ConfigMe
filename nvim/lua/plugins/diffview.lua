return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    -- Keys must be the lazy-load trigger themselves (via lazy.nvim's `keys`),
    -- not set inside `config` — config only runs after the plugin loads,
    -- and with cmd-lazy-loading nothing else ever loads it, so keymaps set
    -- inside config never get created.
    --
    -- Nested under <Leader>g (the "Git" group gitsigns already registers).
    -- gd/gl/gp/gr/gR/gs/gS are taken by gitsigns, gg by lazygit — gv is free.
    keys = {
      { "<Leader>gvo", "<Cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
      { "<Leader>gvc", "<Cmd>DiffviewClose<CR>", desc = "Close Diffview" },
      { "<Leader>gvh", "<Cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<Leader>gvH", "<Cmd>DiffviewFileHistory<CR>", desc = "File history (repo)" },
    },
    config = function() require("diffview").setup {} end,
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>gv"] = { "", desc = "Diffview" },
        },
      },
    },
  },
}
