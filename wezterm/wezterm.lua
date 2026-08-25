local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Default: drop straight into WSL with tmux, mirroring the Ghostty setup on
-- macOS. Plain `tmux new-session` (no -A, no name) so each window gets its own
-- independent session rather than all windows mirroring one shared session.
--
-- `wsl.exe` with a trailing command runs that command inside the default WSL
-- distro; if you switch to a non-default distro, add `"-d", "<distro-name>"`
-- before "tmux" below.
config.default_prog = { "wsl.exe", "tmux", "new-session" }

-- Git Bash stays reachable for the occasional native-Windows task (MinGW
-- toolchains, anything that must see C:\ as a real filesystem rather than
-- through the 9p bridge). Launch it from the new-tab dropdown, or bind a key.
config.launch_menu = {
  {
    label = "WSL + tmux",
    args = { "wsl.exe", "tmux", "new-session" },
  },
  {
    label = "WSL (no tmux)",
    args = { "wsl.exe", "--cd", "~" },
  },
  {
    label = "Git Bash",
    args = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" },
  },
  {
    label = "PowerShell",
    args = { "powershell.exe", "-NoLogo" },
  },
}

-- ALT-SHIFT-L opens the launcher; without a binding the menu is only reachable
-- through the tab-bar dropdown arrow.
config.keys = {
  {
    key = "L",
    mods = "ALT|SHIFT",
    action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
  },
}

return config
