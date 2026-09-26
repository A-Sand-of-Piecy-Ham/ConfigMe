-- Reads features.md -- the checklist of optional features at the repo root --
-- and this machine's overrides, so plugin specs can ask whether a feature is
-- on. See features.md for the format and what switching a feature off does.
--
-- Plugin specs gate on this with `enabled`, never by skipping an import: a
-- disabled plugin keeps its pin in lazy-lock.json, but a skipped import hides
-- the plugin from lazy entirely and its pin is dropped on the next lock
-- update, which would then be committed for every machine.

local M = {}

local state, warned

local function parse(path, into)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return end
  for _, line in ipairs(lines) do
    local box, id = line:match "^%s*[-*]%s+%[([ xX])%]%s+([a-z][a-z0-9-]*)"
    if id then into[id] = box ~= " " end
  end
end

--- The machine-local override file. CONFIGME_FEATURES points elsewhere, for
--- trying a combination without editing the real one.
function M.local_file()
  if vim.env.CONFIGME_FEATURES and vim.env.CONFIGME_FEATURES ~= "" then return vim.env.CONFIGME_FEATURES end
  local base = vim.env.XDG_CONFIG_HOME or (vim.uv.os_homedir() .. "/.config")
  return base .. "/configme/features.md"
end

local function load()
  if state then return state end
  state = {}
  -- The config dir is a symlink (junction on Windows) into the repo, so the
  -- repo's features.md sits one level above its real path.
  local config = vim.uv.fs_realpath(vim.fn.stdpath "config") or vim.fn.stdpath "config"
  local repo_file = vim.fs.find("features.md", { upward = true, path = config })[1]
  if repo_file then parse(repo_file, state) end
  parse(M.local_file(), state)
  return state
end

--- Whether an optional feature is switched on for this machine.
---@param name string an id from features.md
---@return boolean
function M.on(name)
  local value = load()[name]
  if value == nil then
    -- A typo in a spec. Fail open, so a mistake never silently removes
    -- something, but say so once.
    warned = warned or {}
    if not warned[name] then
      warned[name] = true
      vim.schedule(function() vim.notify(("features.lua: unknown feature %q, treating it as on"):format(name), vim.log.levels.WARN) end)
    end
    return true
  end
  return value
end

return M
