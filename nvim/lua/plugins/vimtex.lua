-- LaTeX editing through vimtex: compiling, viewing with synctex, motions, text
-- objects, and a table of contents. The plugin itself is imported from
-- astrocommunity in community.lua, which also supplies which-key descriptions
-- for its maps; the settings are here.
--
-- vimtex reads these options when it loads, and the community module loads it
-- eagerly, so they go in `init`, which runs before that.

---@type LazySpec
return {
  "lervag/vimtex",
  init = function()
    -- Without this, a .tex file with no \documentclass -- a chapter pulled in
    -- with \input from a main document -- is detected as plaintex, and vimtex
    -- does not load for it.
    vim.g.tex_flavor = "latex"

    -- latexmk is vimtex's default; stated so its dependency on
    -- packages/apt.txt is visible from here. It rebuilds on every save.
    vim.g.vimtex_compiler_method = "latexmk"

    -- zathura_simple rather than zathura. The plain variant finds its window
    -- with xdotool, which only sees X11 clients, but under WSLg -- and on
    -- Raspberry Pi OS, which now defaults to Wayland -- zathura runs as a
    -- Wayland client. The simple variant leaves window reuse to zathura
    -- itself over D-Bus, which works on both.
    --
    -- Only when zathura is present, so a machine without it falls back to
    -- vimtex's `general` viewer (xdg-open / open) rather than failing.
    if vim.fn.executable "zathura" == 1 then vim.g.vimtex_view_method = "zathura_simple" end
  end,
}
