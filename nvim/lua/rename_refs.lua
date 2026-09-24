-- Keep HTML and CSS references pointing at files that get renamed or moved,
-- and report every file a rename rewrote.
--
-- AstroNvim already asks language servers to update references on rename:
-- astrolsp.file_operations sends workspace/willRenameFiles before the move and
-- didRenameFiles after it, for both neo-tree and <Leader>R. Two gaps remain,
-- and this module fills them by wrapping those two functions:
--
--   * No HTML or CSS language server implements willRenameFiles -- VS Code's
--     own do not -- so src, href, srcset and url() references were never
--     rewritten. This rewrites them itself, after the move.
--   * The edits land in buffers and are not saved, often buffers that are not
--     on screen, and nothing said so. A notification now lists all of them,
--     whether a language server or this module made them.
--
-- Wrapping instead of listening to neo-tree directly matters: an earlier
-- version of this config sent willRenameFiles again from its own neo-tree
-- handler, so every server was asked twice.

local M = {}

local SCANNED = { html = true, htm = true, css = true }
local URL_ATTRS = { src = true, href = true, poster = true, srcset = true }

-- Relative path from directory `from_dir` to `target`, both absolute and
-- normalized. vim.fs.relpath only handles descendants, so ../ is built here.
local function relative(from_dir, target)
  local a = vim.split(from_dir, "/", { trimempty = true })
  local b = vim.split(target, "/", { trimempty = true })
  local i = 1
  while i <= #a and i <= #b and a[i] == b[i] do
    i = i + 1
  end
  local parts = {}
  for _ = i, #a do
    parts[#parts + 1] = ".."
  end
  for j = i, #b do
    parts[#parts + 1] = b[j]
  end
  return table.concat(parts, "/")
end

-- Where `path` is after the renames, and where it was before them. A rename
-- of a directory carries everything under it.
local function through(path, renames, src, dst)
  for _, r in ipairs(renames) do
    if path == r[src] then return r[dst] end
    if vim.startswith(path, r[src] .. "/") then return r[dst] .. path:sub(#r[src] + 1) end
  end
end
local function moved(path, renames) return through(path, renames, "from", "to") end
local function origin(path, renames) return through(path, renames, "to", "from") end

-- Every URL-valued reference on a line, as { col = 1-based byte, value }.
-- url() and @import are scanned in HTML too, for <style> blocks and style="".
local function references(line, is_html)
  local refs, seen = {}, {}
  local function add(col, value)
    if not seen[col] then
      seen[col], refs[#refs + 1] = true, { col = col, value = value }
    end
  end
  if is_html then
    for attr, _, col, value in line:gmatch "([%a][%w%-]*)%s*=%s*([\"'])()(.-)%2" do
      attr = attr:lower()
      if attr == "srcset" then
        -- "a.png 1x, b.png 2x": each candidate's URL is its first token.
        for off, url in value:gmatch "()([^%s,]+)[^,]*" do
          add(col + off - 1, url)
        end
      elseif URL_ATTRS[attr] then
        add(col, value)
      end
    end
  end
  for _, col, value in line:gmatch "url%(%s*([\"'])()(.-)%1%s*%)" do
    add(col, value)
  end
  for col, value in line:gmatch "url%(%s*()([^%s\"'%)][^%s%)]*)%s*%)" do
    add(col, value)
  end
  for _, col, value in line:gmatch "@import%s+([\"'])()(.-)%1" do
    add(col, value)
  end
  return refs
end

-- Not a local file path: a URL with a scheme, protocol-relative, a fragment,
-- or template syntax that only resolves at build time.
local function is_external(path)
  return path == ""
    or path:find "^%a[%w+.-]*:" ~= nil
    or path:find "^//" ~= nil
    or path:find "{{" ~= nil
    or path:find "{%%" ~= nil
    or path:find "%${" ~= nil
    or path:find "<%%" ~= nil
end

-- The value a reference should have after the renames, or nil to leave it.
-- `file` is where the referencing file is now, `was` where it was before.
local function rewrite(value, file, was, root, renames)
  local path, suffix = value:match "^([^?#]*)(.*)$"
  if is_external(path) then return end
  local encoded = path:find "%%" ~= nil
  local decoded = encoded and vim.uri_decode(path) or path
  local rooted = decoded:sub(1, 1) == "/"
  local old = vim.fs.normalize(rooted and (root .. decoded) or (vim.fs.dirname(was) .. "/" .. decoded))

  local new = moved(old, renames)
  if not new then
    -- The target stayed put. That only matters if the referencing file moved,
    -- and only when the target provably exists: an href to a route or to a
    -- file that was already missing is left exactly as written.
    if file == was or not vim.uv.fs_stat(old) then return end
    new = old
  end

  local out
  if rooted then
    if not vim.startswith(new, root .. "/") then return end
    out = new:sub(#root + 1)
  else
    out = relative(vim.fs.dirname(file), new)
    if path:sub(1, 2) == "./" and not out:find "^%.%./" then out = "./" .. out end
  end
  if encoded then out = out:gsub(" ", "%%20") end
  if out ~= path then return out .. suffix end
end

local function project_files(root)
  local files, seen = {}, {}
  local function keep(p)
    p = vim.fs.normalize(p)
    local ext = (p:match "%.(%w+)$" or ""):lower()
    if SCANNED[ext] and not seen[p] and vim.uv.fs_stat(p) then
      seen[p], files[#files + 1] = true, p
    end
  end
  -- -c alone would list pre-move paths from the index; -o adds the files at
  -- their new, not-yet-staged paths. Both respect .gitignore.
  local git = vim.system({ "git", "-C", root, "ls-files", "-co", "--exclude-standard", "--", "*.html", "*.htm", "*.css" }, { text = true }):wait()
  if git.code == 0 then
    for rel in git.stdout:gmatch "[^\n]+" do
      keep(root .. "/" .. rel)
    end
  else
    local skip = { node_modules = true, [".git"] = true, dist = true, build = true }
    for rel, kind in vim.fs.dir(root, { depth = 20, skip = function(d) return not skip[vim.fs.basename(d)] end }) do
      if kind == "file" then keep(root .. "/" .. rel) end
    end
  end
  return files
end

local function lines_of(file)
  local buf = vim.fn.bufnr(file)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end
  local ok, lines = pcall(vim.fn.readfile, file)
  return ok and lines or {}
end

--- Rewrite HTML/CSS references affected by renames that have already happened.
---@param renames {from: string, to: string}[] absolute, normalized paths
function M.update(renames)
  if #renames == 0 then return end
  local root = vim.fs.root(renames[1].to, ".git") or vim.fn.getcwd()
  local changes = {}
  for _, file in ipairs(project_files(root)) do
    local was = origin(file, renames) or file
    local is_html = file:find "%.html?$" ~= nil
    local edits = {}
    for lnum, line in ipairs(lines_of(file)) do
      for _, ref in ipairs(references(line, is_html)) do
        local new = rewrite(ref.value, file, was, root, renames)
        if new then
          edits[#edits + 1] = {
            range = {
              start = { line = lnum - 1, character = ref.col - 1 },
              ["end"] = { line = lnum - 1, character = ref.col - 1 + #ref.value },
            },
            newText = new,
          }
        end
      end
    end
    if #edits > 0 then changes[vim.uri_from_fname(file)] = edits end
  end
  if next(changes) then vim.lsp.util.apply_workspace_edit({ changes = changes }, "utf-8") end
end

-- astrolsp passes either one rename or a list, with each side a path string
-- or { path = ... }.
local function normalize(renames)
  if renames.from then renames = { renames } end
  local out = {}
  for _, r in ipairs(renames) do
    local from = type(r.from) == "table" and r.from.path or r.from
    local to = type(r.to) == "table" and r.to.path or r.to
    if from and to then
      out[#out + 1] = {
        from = vim.fs.normalize(vim.fn.fnamemodify(from, ":p")),
        to = vim.fs.normalize(vim.fn.fnamemodify(to, ":p")),
      }
    end
  end
  return out
end

local function changedticks()
  local ticks = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    ticks[b] = vim.api.nvim_buf_get_changedtick(b)
  end
  return ticks
end

-- Buffers edited since `before`: new or changed, now modified, and real files.
local function report(before)
  local names = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == "" and vim.bo[b].modified and before[b] ~= vim.api.nvim_buf_get_changedtick(b) then
      names[#names + 1] = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":~:.")
    end
  end
  if #names == 0 then return end
  table.sort(names)
  vim.notify(
    ("Rename updated %d file%s -- unsaved, review then :wa\n  %s"):format(#names, #names == 1 and "" or "s", table.concat(names, "\n  ")),
    vim.log.levels.INFO,
    { title = "Rename" }
  )
end

function M.install()
  local ops = require "astrolsp.file_operations"
  if ops._rename_refs then return end
  ops._rename_refs = true

  local will, did, before = ops.willRenameFiles, ops.didRenameFiles, nil
  ops.willRenameFiles = function(renames)
    before = changedticks()
    return will(renames)
  end
  ops.didRenameFiles = function(renames)
    local ok, err = pcall(M.update, normalize(renames))
    if not ok then vim.notify("HTML/CSS reference update failed:\n" .. tostring(err), vim.log.levels.WARN, { title = "Rename" }) end
    if before then report(before) end
    before = nil
    return did(renames)
  end
end

return M
