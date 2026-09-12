-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  init = function()
    -- harper_ls starts silent but stays running.
    --
    -- Stopping the client hid the findings but made re-enabling a cold start:
    -- the server had to relaunch and re-analyse before saying anything.
    -- Disabling its diagnostic namespace instead leaves it attached and
    -- working, so the toggle only controls whether what it already found is
    -- displayed, and turning it on is instant.
    --
    -- Both namespaces are disabled because a server may deliver diagnostics by
    -- push or by pull, and they are tracked separately.
    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "Start harper_ls muted rather than stopped",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not (client and client.name == "harper_ls") then return end
        for _, pull in ipairs { true, false } do
          vim.diagnostic.enable(false, { ns_id = vim.lsp.diagnostic.get_namespace(client.id, pull) })
        end
      end,
    })
  end,
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = false, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    -- filetypes = {
    --   -- see `:h vim.filetype.add` for usage
    --   extension = {
    --     foo = "fooscript",
    --   },
    --   filename = {
    --     [".foorc"] = "fooscript",
    --   },
    --   pattern = {
    --     [".*/etc/foo/.*"] = "fooscript",
    --   },
    -- },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false, -- sets vim.opt.wrap
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    mappings = {
      n = {
        ["<Leader>us"] = {
          function()
            local clients = vim.lsp.get_clients { name = "harper_ls" }
            if #clients == 0 then
              vim.notify("harper_ls is not attached to this buffer", vim.log.levels.WARN)
              return
            end
            -- Read the current state from one namespace, then apply the
            -- opposite to all of them, so push and pull cannot drift apart.
            local probe = vim.lsp.diagnostic.get_namespace(clients[1].id, true)
            local on = not vim.diagnostic.is_enabled { ns_id = probe }
            for _, c in ipairs(clients) do
              for _, pull in ipairs { true, false } do
                vim.diagnostic.enable(on, { ns_id = vim.lsp.diagnostic.get_namespace(c.id, pull) })
              end
            end
            vim.notify("spellcheck " .. (on and "on" or "off"))
          end,
          desc = "Toggle spellcheck",
        },
      },
    },
  },
}
