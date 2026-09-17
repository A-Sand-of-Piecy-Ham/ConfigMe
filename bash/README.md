# Bash configuration

Split by platform, because a single file cannot serve Homebrew on macOS,
apt and nvm on WSL, and MinGW on Windows.

| File | Used on |
|---|---|
| `common.sh` | all -- PATH, aliases, `EDITOR`, ccache. Linked to `~/.config/dotfiles/common.sh` and sourced by each of the below. |
| `bashrc.darwin`, `bash_profile.darwin` | macOS (Homebrew, Rancher Desktop) |
| `bashrc.linux`, `bash_profile.linux` | Linux and WSL (nvm, cargo, `~/.local/bin`) |
| `bashrc.windows`, `bash_profile.windows` | Git Bash / MSYS2 |

Anything platform-specific belongs in the per-OS file, never in `common.sh`.
The installer links the pair matching the detected platform, so a machine only
ever has one `bashrc` and one `bash_profile` in play.
