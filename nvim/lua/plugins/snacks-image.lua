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
--
-- Also patches a crash on inline `data:` URIs -- see patch_data_uri_cache below.

-- snacks derives the cache filename for an inline `data:image/...;base64,...`
-- image from the first 20 characters of the raw base64. The base64 alphabet
-- includes `/`, so the name can contain path separators, and io.open then fails
-- on a directory that does not exist. Every 1x1 transparent GIF -- the standard
-- tracking or spacer pixel, common in HTML and in markdown converted from it --
-- encodes to `R0lGODlhAQABAIAAAP///...`, so those hit this on every render.
--
-- Clearing content_id after the transform runs drops snacks onto its own
-- fallback on the very next line, a hex prefix of the content's sha256, which
-- cannot contain a separator. content_id is used for nothing but that filename.
--
-- Upstream as of snacks 2.31.0 (2026-09): unfixed on main, no issue filed.
-- Harmless if upstream fixes it -- it only ever clears a field the fallback
-- replaces -- so there is no need to remove this in lockstep.
local function patch_data_uri_cache()
  local ok, doc = pcall(require, "snacks.image.doc")
  local orig = ok and doc.transforms and doc.transforms.data_img
  if not orig then return end -- upstream reshaped the module; nothing to patch
  doc.transforms.data_img = function(img, ctx)
    orig(img, ctx)
    img.content_id = nil
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      patch_data_uri_cache()
      return vim.tbl_deep_extend("force", opts, {
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
      })
    end,
  },
}
