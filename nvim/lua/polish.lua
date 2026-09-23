-- Runs last in the setup process. Pure lua for anything that does not fit the
-- normal config locations.

-- Strip carriage returns from pasted text.
--
-- Text copied in a Windows application arrives through the WSLg clipboard
-- bridge with CRLF line endings, so every pasted line ended in a literal ^M.
--
-- kitty now strips these itself (kitty/paste-actions.py), but this wrapper
-- stays: Neovim also runs under terminals that do not, and over SSH the paste
-- may never pass through kitty at all.
--
-- vim.paste is what Neovim calls for bracketed paste -- the path a terminal
-- paste takes. It does not cover reading the clipboard as a register; that is
-- the provider below.
local orig_paste = vim.paste
vim.paste = function(lines, phase)
  for i, line in ipairs(lines) do
    lines[i] = line:gsub("\r$", "")
  end
  return orig_paste(lines, phase)
end

-- The same carriage returns, arriving by the other route.
--
-- The vim.paste wrapper above only sees text the terminal pastes in. Reading
-- the system clipboard as a register -- `"+p`, `"*p`, `<C-r>+` in insert mode
-- -- goes through the clipboard provider instead and never touches vim.paste,
-- so CRLF text from a Windows application landed with a ^M on every line.
--
-- This replaces the provider with one that reads the same tool Neovim would
-- have picked and strips CR on the way in. Copying out is left byte-for-byte
-- identical. Detection follows Neovim's own precedence, and if none of these
-- apply, g:clipboard is left unset so Neovim's default detection runs exactly
-- as it would have -- the fallback is today's behaviour, never a dead clipboard.
do
  local function has(exe) return vim.fn.executable(exe) == 1 end

  local tool
  if vim.fn.has "mac" == 1 and has "pbcopy" then
    tool = {
      name = "pbcopy",
      copy = { ["+"] = { "pbcopy" }, ["*"] = { "pbcopy" } },
      paste = { ["+"] = { "pbpaste" }, ["*"] = { "pbpaste" } },
    }
  elseif vim.env.WAYLAND_DISPLAY and has "wl-copy" and has "wl-paste" then
    tool = {
      name = "wl-clipboard",
      copy = {
        ["+"] = { "wl-copy", "--foreground", "--type", "text/plain" },
        ["*"] = { "wl-copy", "--foreground", "--primary", "--type", "text/plain" },
      },
      paste = {
        ["+"] = { "wl-paste", "--no-newline" },
        ["*"] = { "wl-paste", "--no-newline", "--primary" },
      },
    }
  elseif vim.env.DISPLAY and has "xclip" then
    tool = {
      name = "xclip",
      copy = {
        ["+"] = { "xclip", "-quiet", "-i", "-selection", "clipboard" },
        ["*"] = { "xclip", "-quiet", "-i", "-selection", "primary" },
      },
      paste = {
        ["+"] = { "xclip", "-o", "-selection", "clipboard" },
        ["*"] = { "xclip", "-o", "-selection", "primary" },
      },
    }
  elseif vim.env.DISPLAY and has "xsel" then
    tool = {
      name = "xsel",
      copy = { ["+"] = { "xsel", "--nodetach", "-i", "-b" }, ["*"] = { "xsel", "--nodetach", "-i", "-p" } },
      paste = { ["+"] = { "xsel", "-o", "-b" }, ["*"] = { "xsel", "-o", "-p" } },
    }
  end

  if tool then
    -- Mirror how Neovim's own provider derives the register type: output that
    -- ends in a newline is linewise, anything else is charwise. Getting this
    -- wrong changes where `p` puts the text, not just what it contains.
    local function reader(cmd)
      return function()
        local out = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then return { {}, "v" } end
        out = out:gsub("\r\n", "\n"):gsub("\r", "\n")
        local linewise = out:sub(-1) == "\n"
        if linewise then out = out:sub(1, -2) end
        return { vim.split(out, "\n", { plain = true }), linewise and "V" or "v" }
      end
    end

    vim.g.clipboard = {
      name = tool.name .. " (CR-stripping)",
      copy = tool.copy,
      paste = { ["+"] = reader(tool.paste["+"]), ["*"] = reader(tool.paste["*"]) },
      -- Must stay 1. With caching off, Neovim runs the copy command
      -- synchronously, and xclip/xsel/wl-copy in these forms never exit --
      -- they stay in the foreground to serve the selection -- so every `"+y`
      -- would freeze the editor. Caching on runs copy as a detached job
      -- instead. The cache only ever holds text Neovim itself copied, which
      -- has no carriage returns, so it cannot resurrect the ^M.
      cache_enabled = 1,
    }
  end
end
