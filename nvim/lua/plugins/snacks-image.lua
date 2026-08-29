-- Inline image rendering.
--
-- Uses snacks.nvim's image module rather than a dedicated plugin: snacks is
-- already an AstroNvim v6 core dependency, so this adds no new plugin, and it
-- covers more than 3rd/image.nvim does -- LaTeX math via tectonic, Mermaid
-- diagrams via mmdc, and PDF via ghostscript, alongside plain images.
--
-- AstroNvim ships `opts.image = { doc = { enabled = false } }`, which disables
-- exactly the inline-in-document rendering we want, so this re-enables it.
--
-- Requires ImageMagick on PATH (magick, or convert/identify on ImageMagick 6)
-- and a terminal speaking the kitty graphics protocol. Under kitty this gets
-- unicode placeholder support, so images occupy real cells and scroll, clip,
-- and redraw with the buffer. WezTerm reports placeholders = false and falls
-- back to absolute positioning, which is why images flicker there.
--
-- tmux also needs the passthrough settings; see tmux/.tmux.conf.
return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = {
          enabled = true,
          -- Render inline rather than only in a hover window. Requires
          -- placeholder support, and snacks disables it on its own where the
          -- terminal lacks it, so this is safe to leave on under WezTerm.
          inline = true,
          float = true,
          max_width = 80,
          max_height = 30,
        },
        -- Images are drawn over the terminal grid, so anything that paints on
        -- top has to force a redraw. Leaving these at the defaults is right;
        -- listed here so it is obvious where to tune if popups smear.
        convert = {
          notify = true, -- surface ImageMagick failures instead of silence
        },
      },
    },
  },
}
