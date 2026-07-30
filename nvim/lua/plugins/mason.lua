---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- language servers
        "harper-ls",
        "astro-language-server",
        "bash-language-server",
        "clangd",
        "eslint-lsp",
        "lua-language-server",
        "nginx-language-server",
        "taplo",
        "typescript-language-server",

        -- debuggers
        "codelldb",
        "cpptools",
        "java-debug-adapter",
        "java-test",
        "jdtls",
        "vscode-spring-boot-tools",

        -- formatters / linters
        "ast-grep",
        "selene",
        "stylua",

        -- other
        "tree-sitter-cli",
      },
    },
  },
}
