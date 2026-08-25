# Shared bash configuration, sourced by every per-OS bashrc.
# Keep this file free of anything platform-specific — brew, wsl.exe, Windows
# paths, and Rancher Desktop all belong in the bashrc.<os> that needs them.

export USE_CCACHE=1

# ~/.local/bin is where pipx, uv, and hand-installed tools land. Ubuntu's
# .profile adds it, but only for login shells; `wsl -- <cmd>` and most
# editor/agent integrations start non-login shells, where it would be missing.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

# Rust toolchain, if rustup put one here.
[ -d "$HOME/.cargo/bin" ] && case ":$PATH:" in
  *":$HOME/.cargo/bin:"*) ;;
  *) PATH="$HOME/.cargo/bin:$PATH" ;;
esac

export EDITOR=nvim
export VISUAL=nvim

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim=nvim
