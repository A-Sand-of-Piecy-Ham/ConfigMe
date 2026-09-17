---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      -- Deliberately excludes anything an imported astrocommunity pack already
      -- manages. The packs gate their tooling by architecture:
      --
      --   pack.cpp  codelldb always; clangd only when not linux-arm
      --   pack.lua  lua-language-server + stylua always; selene only when not aarch64
      --   pack.rust codelldb
      --
      -- Listing those here as well overrode the gate and forced a mason install
      -- on ARM, where no upstream build exists. That is why clangd and selene
      -- failed on the Pi while the packs were written to skip them.
      ensure_installed = {
        -- language servers
        "harper-ls", -- grammar; toggled in astrocore.lua
        "bash-language-server",
        -- Python: ty is the attaching server; basedpyright stays installed but
        -- is not auto-enabled (see astrolsp.lua handlers). Keeping it installed
        -- means `:LspStart basedpyright` is always one command away for the
        -- stricter second opinion and for go-to-implementation, which ty lacks.
        "ty", -- python type checker + LSP (Rust)
        "basedpyright", -- python: stricter checker, started on demand
        "json-lsp",
        "jdtls",
        "marksman", -- markdown
        "nginx-language-server",
        "taplo", -- toml
        "typescript-language-server",
        "eslint-lsp",
        "yaml-language-server",

        -- hardware / shading languages
        "verible", -- systemverilog: formatter + linter + LSP
        "glsl_analyzer",
        "wgsl-analyzer",

        -- debuggers
        "cpptools",
        "java-debug-adapter",
        "java-test",
        "vscode-spring-boot-tools",

        -- formatters / linters
        "ruff", -- python lint + format

        -- other
        "ast-grep",
        "tree-sitter-cli",
      },
    },
  },
}
