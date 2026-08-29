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

# ------------------------------------------------------------- kittens ------
# kitty ships subprograms ("kittens") that use terminal protocols an ordinary
# command cannot reach. These only work when the terminal is kitty, so they are
# guarded rather than defined unconditionally -- a broken alias on a machine
# without kitty is worse than a missing one.
if command -v kitten >/dev/null 2>&1; then
    # Display an image in the terminal itself.
    alias icat='kitten icat'

    # ripgrep whose results are OSC 8 hyperlinks, so a hit can be opened
    # directly rather than retyped.
    alias hgrep='kitten hyperlinked_grep'

    # Side-by-side, syntax-highlighted diff that can also render changed
    # images. Useful outside nvim, where diffview.nvim covers this.
    alias kdiff='kitten diff'

    # Read and write the system clipboard from a pipe. Works over SSH, since it
    # travels as an escape sequence rather than needing a display.
    alias clip='kitten clipboard'

    # ssh that carries kitty's terminfo to the remote host, so TERM=xterm-kitty
    # does not leave you with a broken remote shell. Only shadow ssh when
    # actually running under kitty.
    if [ "${TERM:-}" = "xterm-kitty" ]; then
        alias ssh='kitten ssh'
    fi
fi
