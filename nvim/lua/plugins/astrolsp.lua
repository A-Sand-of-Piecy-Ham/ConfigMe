-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
-- checkJs brings TypeScript's strict mode, whose demands suit annotated code
-- and not plain JavaScript: every untyped parameter and getElementById() result
-- becomes an error. `strict = false` cannot switch it off, because
-- typescript-language-server only forwards the option when it is true, so these
-- are dropped here instead, for JS files only.
local JS_IGNORED_CODES = {
  [2531] = true, -- object is possibly 'null'
  [2532] = true, -- object is possibly 'undefined'
  [2533] = true, -- object is possibly 'null' or 'undefined'
  [7005] = true, -- variable implicitly has an 'any' type
  [7006] = true, -- parameter implicitly has an 'any' type
  [7017] = true, -- globalThis.x: 'typeof globalThis' has no index signature
  [7031] = true, -- binding element implicitly has an 'any' type
  [7034] = true, -- variable implicitly has type 'any' in some locations
  [7053] = true, -- obj[key]: expression can't be used to index the type
  [18047] = true, -- 'x' is possibly 'null'
  [18048] = true, -- 'x' is possibly 'undefined'
  [18049] = true, -- 'x' is possibly 'null' or 'undefined'
}

local function without_js_annotation_noise(err, result, ctx)
  if result and result.uri:match "%.[cm]?jsx?$" then
    result.diagnostics = vim.tbl_filter(
      function(diagnostic) return not JS_IGNORED_CODES[diagnostic.code] end,
      result.diagnostics
    )
  end
  return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
end

local spec = {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      -- codelens is left to AstroNvim, which computes it per Neovim version:
      -- it disables codelens on 0.12.0 - 0.12.1 where upstream is broken.
      -- Forcing it true here overrode that guard.
      inlay_hints = false, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = false, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      -- "pyright"
    },
    -- customize language server configuration passed to `vim.lsp.config`
    -- client specific configuration can also go in `lsp/` in your configuration root (see `:h lsp-config`)
    config = {
      -- ["*"] = { capabilities = {} }, -- modify default LSP client settings such as capabilities
      -- TypeScript reports only syntax errors in plain JavaScript unless checkJs
      -- is on, so undefined variables went unreported. This covers JS outside a
      -- jsconfig.json/tsconfig.json; a project with one uses its own settings.
      ts_ls = {
        settings = { implicitProjectConfiguration = { checkJs = true } },
        handlers = { ["textDocument/publishDiagnostics"] = without_js_annotation_noise },
      },
      harper_ls = {
        settings = {
          ["harper-ls"] = {
            linters = {
              SentenceCapitalization = false,
              LongSentences = false,
              AnA = false,
              ExpandParam = false,
            },
          },
        },
      },
      clangd = {
        formatting = {
          format_on_save = {
            enabled = false,
          },
        }
      },
      -- texlab supplies the language features. Compiling and viewing belong to
      -- vimtex (plugins/vimtex.lua), so texlab's own build and forward-search
      -- settings are deliberately left unset rather than duplicating it.
      texlab = {
        settings = {
          texlab = {
            -- tex-fmt is a single Rust binary from Mason; the default,
            -- latexindent, is a Perl script and far slower on each format.
            latexFormatter = "tex-fmt",
            bibtexFormatter = "tex-fmt",
            -- chktex lint findings as ordinary diagnostics. Needs chktex from
            -- packages/apt.txt; without it this reports nothing.
            chktex = { onOpenAndSave = true },
          },
        },
      },
    },
    -- customize how language servers are attached
    handlers = {
      -- jdtls is configured manually in plugins/jdtls.lua to pass debug/test bundles
      jdtls = false,
      -- Python attaches ty, not basedpyright. Rationale: both are type checkers
      -- and language servers covering the same ground, but basedpyright runs on
      -- a bundled Node and is by a wide margin the most memory-hungry server in
      -- this config, while ty is a single Rust binary. ty also delegates
      -- formatting to ruff, which is already attached.
      --
      -- basedpyright is deliberately still installed, not removed. It is the
      -- stricter checker and ty is pre-1.0, so `:LspStart basedpyright` is the
      -- escape hatch for a second opinion on any buffer.
      --
      -- A `false` handler means astrolsp never calls vim.lsp.enable for it; see
      -- astrolsp.lsp_setup. Run `./install.sh --doctor` to re-measure the
      -- memory and capability claims above against what is actually installed.
      basedpyright = false,
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        -- Optional condition to create/delete auto command group
        -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
        -- condition will be resolved for each client on each execution and if it ever fails for all clients,
        -- the auto commands will be deleted for that buffer
        cond = "textDocument/codeLens",
        -- cond = function(client, bufnr) return client.name == "lua_ls" end,
        -- list of auto commands to set
        -- Codelens refresh is deliberately NOT handled here. astrolsp already
        -- does it, and does it safely: vim.lsp.codelens.enable does not exist
        -- on every Neovim (it is absent on 0.12.0-dev), so astrolsp falls back
        -- to vim.lsp.codelens.refresh and guards every call. The copy that used
        -- to live here called .enable unguarded and threw E5108 on BufEnter for
        -- any buffer whose server publishes codelens, such as JavaScript.
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
    --     -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
        ["gD"] = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        -- Override <Leader>lR to explicitly open Telescope references
        ["<Leader>lR"] = {
          function()
            require("telescope.builtin").lsp_references({
              fname_width = 50,
              trim_text = true,
              layout_strategy = "horizontal",
            })
          end,
          desc = "Search references in Telescope",
        },
        -- Optional: Bind standard 'gr' to the same Telescope function
        ["gr"] = {
          function()
            require("telescope.builtin").lsp_references()
          end,
          desc = "Go to references (Telescope)",
        },
    --     ["<Leader>uY"] = {
    --       function() require("astrolsp.toggles").buffer_semantic_tokens() end,
    --       desc = "Toggle LSP semantic highlight (buffer)",
    --       cond = function(client)
    --         return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
    --       end,
    --     },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    -- takes two parameters `client` and `bufnr`  (`:h lsp-attach`)
    on_attach = function(client, bufnr)
      -- this would disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}

-- Optional features (features.md). Turning one off stops its servers from
-- attaching even where they are already installed; a `false` handler means
-- astrolsp never calls vim.lsp.enable for that server.
local feature = require("features").on
if not feature "latex" then spec.opts.handlers.texlab = false end
-- pack.rust normally sets this, so rustaceanvim alone drives rust-analyzer.
-- With rust off the pack is skipped, and an installed rust-analyzer would
-- otherwise be started through plain lspconfig.
if not feature "rust" then spec.opts.handlers.rust_analyzer = false end
if not feature "hardware" then
  for _, server in ipairs { "verible", "glsl_analyzer", "wgsl_analyzer" } do
    spec.opts.handlers[server] = false
  end
end

return spec


-- return {
--   "AstroNvim/astrolsp",
--   opts = {
--     config = {
--       clangd = {
--         root_dir = function(fname)
--           local util = require("lspconfig.util")
--           return util.find_git_ancestor(fname) or util.path.dirname(fname)
--         end,
--       },
--     },
--   },
-- }
