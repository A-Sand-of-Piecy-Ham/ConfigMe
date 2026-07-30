return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local jdtls = require "jdtls"
      local mason_path = vim.fn.stdpath "data" .. "/mason/packages"

      local bundles = {}
      vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n", { trimempty = true }))
      vim.list_extend(bundles, vim.split(vim.fn.glob(mason_path .. "/java-test/extension/server/*.jar"), "\n", { trimempty = true }))

      local root_dir = jdtls.setup.find_root { "gradlew", "mvnw", ".git" }

      local config = {
        cmd = { vim.fn.stdpath "data" .. "/mason/bin/jdtls" },
        root_dir = root_dir,
        init_options = {
          bundles = bundles,
          extendedClientCapabilities = jdtls.extendedClientCapabilities,
        },
        on_attach = function(client, bufnr)
          jdtls.setup_dap { hotcodereplace = "auto" }

          local map = function(key, fn, desc)
            vim.keymap.set("n", key, fn, { buffer = bufnr, silent = true, desc = desc })
          end

          local ok, wk = pcall(require, "which-key")
          if ok then wk.add { { "<Leader>j", group = "Java", buffer = bufnr } } end

          map("<Leader>jt", jdtls.test_nearest_method, "Test nearest method")
          map("<Leader>jT", jdtls.test_class, "Test class")
          map("<Leader>jo", jdtls.organize_imports, "Organize imports")
        end,
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function() jdtls.start_or_attach(config) end,
      })

      if vim.bo.filetype == "java" then jdtls.start_or_attach(config) end
    end,
  },
}
