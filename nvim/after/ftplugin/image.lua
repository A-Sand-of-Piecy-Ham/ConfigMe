-- Zoom for image buffers. snacks.image sets this filetype.
--
-- snacks.image has no zoom and never enlarges: util.fit returns the native size
-- whenever it fits the window, so an 8x8 PNG occupies about one text cell. Each
-- step therefore writes a resized copy and points the same buffer at it, using
-- nearest-neighbour so that small images stay sharp rather than blurring.
--
-- snacks still shrinks anything larger than the window to fit, so zooming in
-- stops having a visible effect at window size. There is no panning.

local buf = vim.api.nvim_get_current_buf()
local src = vim.api.nvim_buf_get_name(buf)

-- A picker preview also uses this filetype, but its buffer is not named after
-- the file, so there is nothing here to resize.
if vim.fn.filereadable(src) == 0 then return end

local MIN_ZOOM, MAX_ZOOM = 0.125, 64
-- Guards the conversion: 64x on an already large image would exhaust memory.
local MAX_SIDE = 4096

local function imagemagick(tool, args)
  -- ImageMagick 6, which Ubuntu ships, has convert/identify but no `magick`.
  local cmd = vim.fn.executable "magick" == 1 and { "magick", tool ~= "convert" and tool or nil } or { tool }
  return vim.list_extend(cmd, args)
end

local function longest_side()
  local res = vim.system(imagemagick("identify", { "-format", "%w %h", src .. "[0]" }), { text = true }):wait()
  local w, h = (res.stdout or ""):match "(%d+) (%d+)"
  return w and math.max(tonumber(w), tonumber(h))
end

local function show(zoom, file)
  Snacks.image.buf.attach(buf, file and { src = file } or nil)
  vim.api.nvim_echo({ { ("zoom %d%%"):format(zoom * 100) } }, false, {})
end

local function set_zoom(zoom)
  vim.b[buf].image_zoom = zoom
  if zoom == 1 then return show(zoom) end

  local out = vim.fn.tempname() .. ".png"
  local args = { src .. "[0]", "-filter", "point", "-resize", ("%g%%"):format(zoom * 100), out }
  vim.system(
    imagemagick("convert", args),
    {},
    vim.schedule_wrap(function(res)
      -- A later key press has already superseded this conversion.
      if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].image_zoom ~= zoom then return end
      if res.code ~= 0 then
        vim.b[buf].image_zoom = 1
        vim.notify("image zoom: " .. (res.stderr or "conversion failed"), vim.log.levels.ERROR)
        return
      end
      show(zoom, out)
    end)
  )
end

local function current() return vim.b[buf].image_zoom or 1 end

local function map(key, fn, desc) vim.keymap.set("n", key, fn, { buffer = buf, silent = true, desc = desc }) end

map("+", function()
  local zoom = current() * 2
  local side = longest_side()
  if zoom > MAX_ZOOM or not side or side * zoom > MAX_SIDE then
    vim.api.nvim_echo({ { ("zoom %d%% (maximum)"):format(current() * 100) } }, false, {})
    return
  end
  set_zoom(zoom)
end, "Zoom image in")

map("-", function() set_zoom(math.max(current() / 2, MIN_ZOOM)) end, "Zoom image out")
map("=", function() set_zoom(1) end, "Reset image zoom")
