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
        -- Not via astrocommunity.pack.astro: it imports pack.typescript,
        -- which installs vtsls and runs it beside ts_ls. See astrolsp.lua.
        "astro-language-server",
        "html-lsp", -- VS Code's HTML server: tag/attribute completion, hover, href/src links
        "css-lsp", -- VS Code's CSS server: completion, validation, color swatches
        "eslint-lsp",
        "yaml-language-server",
        "texlab", -- latex: \ref/\cite/label completion, chktex diagnostics
        -- pack.rust installs codelldb but not the server, and rustup's
        -- /usr/bin/rust-analyzer is a placeholder that errors unless the
        -- rust-analyzer component is added, so a fresh machine had no Rust LSP.
        "rust-analyzer",

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
        "tex-fmt", -- latex/bibtex formatter, run through texlab (see astrolsp.lua)

        -- other
        "ast-grep",
        "tree-sitter-cli",
      },
    },
  },
}
