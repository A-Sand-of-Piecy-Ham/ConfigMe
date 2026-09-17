-- Live preview for HTML/CSS/JS (and markdown) in a browser, reloading on save.
--
-- Chosen over bracey.vim and live-server.nvim because it runs a Lua server
-- in-process: no npm package to install, which matters on machines where node
-- comes from nvm and may be absent entirely.
--
-- Under WSL the browser is on the Windows side, so `browser` points at wslview
-- rather than letting it guess; without that it opens nothing and fails quietly.
return {
  {
    "brianhuster/live-preview.nvim",
    cmd = { "LivePreview" },
    ft = { "html", "css", "javascript", "markdown" },
    opts = function()
      local browser = "default"
      if vim.fn.executable "wslview" == 1 then browser = "wslview" end
      return {
        port = 5500,
        browser = browser,
        -- Only reload on write. Reloading on every keystroke re-runs scripts
        -- mid-edit, which is noisy for JS with side effects.
        autokill = true,
      }
    end,
    keys = {
      { "<Leader>lp", "<cmd>LivePreview start<cr>", desc = "Live preview: start" },
      { "<Leader>lP", "<cmd>LivePreview close<cr>", desc = "Live preview: stop" },
    },
  },
}
