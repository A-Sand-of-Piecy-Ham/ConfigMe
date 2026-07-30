return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },

    -- init = function()
    --   pcall(vim.keymap.del, "n", "<leader>h")
    -- end

    config = function()
      -- print("harpoon config loaded")

      local harpoon = require("harpoon")

      harpoon:setup({})

      -- Add file
      vim.keymap.set("n", "<leader>ha", function()
        harpoon:list():add()
      end, { desc = "Harpoon Add File" })

      -- Toggle menu (edit to reorder/remove entries)
      vim.keymap.set("n", "<leader>hm", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon Menu" })

      -- Quick navigation by slot
      vim.keymap.set("n", "<leader>h1", function()
        harpoon:list():select(1)
      end, { desc = "Harpoon File 1" })

      vim.keymap.set("n", "<leader>h2", function()
        harpoon:list():select(2)
      end, { desc = "Harpoon File 2" })

      vim.keymap.set("n", "<leader>h3", function()
        harpoon:list():select(3)
      end, { desc = "Harpoon File 3" })

      vim.keymap.set("n", "<leader>h4", function()
        harpoon:list():select(4)
      end, { desc = "Harpoon File 4" })

      -- -- Home menu
      -- vim.keymap.set("n", "<leader>h.", function()
      --   require() 
      -- end, { desc = "Home menu" })

      -- Telescope integration
      vim.keymap.set("n", "<leader>hs", function()
        local conf = require("telescope.config").values

        local file_paths = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end, { desc = "Search Harpoon with Telescope" })
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          -- Lands right inside the standard "Buffers" (<Leader>b) helper menu
          ["<Leader>h"] = { "", desc = "Harpoon" },
        },
      },
    },
  },
}
