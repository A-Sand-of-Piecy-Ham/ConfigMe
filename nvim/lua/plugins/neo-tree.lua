-- Propagate file renames and moves made in the file tree to the language
-- servers, so imports and references are rewritten instead of silently
-- breaking.
--
-- Neovim core never sends `workspace/willRenameFiles` by itself: the request
-- has to originate from whatever performed the rename. snacks.nvim ships the
-- client half of this, but nothing subscribes it to neo-tree's events, so
-- servers advertising the capability were never actually asked.
--
-- Servers that ignore the request simply do not respond to it, so this is safe
-- to leave wired regardless of which ones are attached. `./install.sh --doctor`
-- reports which of the installed servers currently advertise the capability.

---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    local function on_move(data)
      require("snacks").rename.on_rename_file(data.source, data.destination)
    end

    local events = require "neo-tree.events"
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      { event = events.FILE_MOVED, handler = on_move },
      { event = events.FILE_RENAMED, handler = on_move },
    })
  end,
}
