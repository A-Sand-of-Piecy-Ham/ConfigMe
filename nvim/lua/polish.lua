-- Runs last in the setup process. Pure lua for anything that does not fit the
-- normal config locations.

-- Strip carriage returns from pasted text.
--
-- Text copied in a Windows application arrives through the WSLg clipboard
-- bridge with CRLF line endings, so every pasted line ended in a literal ^M.
-- The terminal does not strip it: kitty's paste_actions can replace control
-- codes it considers dangerous, but a bare CR is not one of them.
--
-- vim.paste is what Neovim calls for bracketed paste, which is the path a
-- terminal paste takes, so wrapping it catches the case regardless of which
-- register or mapping is involved.
local orig_paste = vim.paste
vim.paste = function(lines, phase)
  for i, line in ipairs(lines) do
    lines[i] = line:gsub("\r$", "")
  end
  return orig_paste(lines, phase)
end
