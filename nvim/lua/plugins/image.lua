-- Inline image rendering via the terminal's graphics protocol.
--
-- Terminal caveat: this stack is WezTerm -> wsl.exe -> tmux -> nvim, and
-- image.nvim does not officially support WezTerm. WezTerm implements Kitty's
-- graphics protocol but, per upstream, "performance is bad and it's not fully
-- compliant". Most things work; expect flicker and slow redraws on large
-- images. Kitty or Ghostty are the supported options if this proves annoying.
--
-- tmux must also be configured for this to work at all; see the passthrough
-- block in tmux/.tmux.conf.
return {
  {
    "3rd/image.nvim",
    -- Skips the luarocks build. The magick_rock processor wants a Lua rock
    -- built against ImageMagick's development headers; magick_cli below just
    -- shells out to the binaries instead, which is one less thing to break on
    -- a distro that only ships ImageMagick 6.
    build = false,
    ft = { "markdown", "vimwiki", "norg" },
    opts = {
      -- Ubuntu 24.04 ships ImageMagick 6, which provides convert/identify but
      -- no `magick` binary. image.nvim's CLI processor detects this and falls
      -- back automatically, so no ImageMagick 7 install is needed.
      processor = "magick_cli",
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          -- Only fetch remote images on demand; otherwise opening a README
          -- full of badge URLs blocks on network requests.
          download_remote_images = false,
          only_render_image_at_cursor = true,
          filetypes = { "markdown", "vimwiki" },
        },
        neorg = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
      max_width_window_percentage = 80,
      -- Leave room for the statusline and a few lines of context rather than
      -- letting a tall image push everything else off screen.
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "" },
      editor_only_render_when_focused = true,
      -- Required with tmux: images are drawn over the terminal, so nvim has to
      -- stop drawing them when the pane is not the active one.
      tmux_show_only_in_active_window = true,
    },
  },
}
