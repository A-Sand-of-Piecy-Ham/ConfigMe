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
        "basedpyright", -- python: the most-used language here and previously absent
        "json-lsp",
        "jdtls",
        "marksman", -- markdown
        "nginx-language-server",
        "taplo", -- toml
        "typescript-language-server",
        "eslint-lsp",
        "yaml-language-server",

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
