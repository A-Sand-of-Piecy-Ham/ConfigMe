-- Propagate file renames and moves made in the file tree to the language
-- servers, so imports and references are rewritten instead of silently
-- breaking.
--
-- Neovim core never sends `workspace/willRenameFiles` by itself: the request
-- has to originate from whatever performed the rename. This does what
-- snacks.rename.on_rename_file does, with two differences that both address a
-- silent failure:
--
--   * It reports every file it changed. The edits land in buffers and are not
--     saved -- often buffers that are not even visible -- so without a report
--     a rename could leave half the project updated in memory and stale on
--     disk with nothing to show for it. Review, then :wa.
--   * A server gets 5s to answer instead of snacks' 1s, and one that misses the
--     deadline is reported rather than skipped. The first rename in a project
--     is the slow one, since the server may still be building its view of it.
--
-- Only servers that are running can answer. Renaming a module while none of
-- its importers' language servers are attached updates nothing, and nothing
-- here can know that it should have.

local TIMEOUT_MS = 5000

-- Every file a workspace edit touches, in either of the two shapes the
-- protocol allows.
local function edited_files(edit, into)
  for uri in pairs(edit.changes or {}) do
    into[vim.uri_to_fname(uri)] = true
  end
  for _, change in ipairs(edit.documentChanges or {}) do
    if change.textDocument then into[vim.uri_to_fname(change.textDocument.uri)] = true end
  end
end

local function on_move(data)
  local files = { { oldUri = vim.uri_from_fname(data.source), newUri = vim.uri_from_fname(data.destination) } }
  local changed, silent = {}, {}

  for _, client in ipairs(vim.lsp.get_clients()) do
    if client:supports_method "workspace/willRenameFiles" then
      local resp = client:request_sync("workspace/willRenameFiles", { files = files }, TIMEOUT_MS, 0)
      if not resp or resp.err then
        silent[#silent + 1] = client.name
      elseif resp.result then
        edited_files(resp.result, changed)
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client:supports_method "workspace/didRenameFiles" then client:notify("workspace/didRenameFiles", { files = files }) end
  end

  local names = vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ":~:.") end, vim.tbl_keys(changed))
  table.sort(names)
  if #names > 0 then
    vim.notify(
      ("Rename updated %d file%s -- unsaved, review then :wa\n  %s"):format(#names, #names == 1 and "" or "s", table.concat(names, "\n  ")),
      vim.log.levels.INFO,
      { title = "Rename" }
    )
  end
  if #silent > 0 then
    vim.notify(
      ("%s did not answer; references it manages were NOT updated"):format(table.concat(silent, ", ")),
      vim.log.levels.WARN,
      { title = "Rename" }
    )
  end
end

---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    local events = require "neo-tree.events"
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      { event = events.FILE_MOVED, handler = on_move },
      { event = events.FILE_RENAMED, handler = on_move },
    })
  end,
}
