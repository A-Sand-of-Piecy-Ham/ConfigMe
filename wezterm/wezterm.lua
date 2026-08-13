local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Auto-start tmux inside WSL for every new window/tab, mirroring the
-- Ghostty setup on macOS. Plain `tmux new-session` (no -A, no name) so each
-- window gets its own independent session rather than all windows mirroring
-- one shared session.
--
-- NOTE: untested — there is no Windows/WezTerm install to verify this
-- against yet. `wsl.exe` with a trailing command runs that command inside
-- the default WSL distro; if you use a non-default distro, add
-- `"-d", "<distro-name>"` before "tmux" below.
config.default_prog = { "wsl.exe", "tmux", "new-session" }

return config
