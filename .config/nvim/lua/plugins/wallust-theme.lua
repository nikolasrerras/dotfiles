-- Neovim colors that follow the `theme` selector.
--
-- * Themes with a real Neovim colorscheme (Gruvbox, Catppuccin, Tokyo Night…)
--   load that colorscheme, in the matching variant.
-- * Every other theme falls back to a base16 scheme (mini.base16) built from
--   the wallust palette.
-- Reloads live whenever the theme changes.

local palette_file = vim.fn.expand("~/.cache/wallust/colors.sh")
local current_file = vim.fn.expand("~/.cache/theme/current")

-- ───────────── theme name → real colorscheme ─────────────
-- Keys are normalized: lowercase, letters and digits only
-- ("Gruvbox-Dark" and "GruvboxDark" both become "gruvboxdark").
-- Note: "é" is dropped, so "Rosé-Pine" becomes "rospine".

local function everforest(level)
  return function()
    vim.g.everforest_background = level
  end
end

local schemes = {
  gruvbox = { cs = "gruvbox" },
  gruvboxdark = { cs = "gruvbox" },
  base16gruvboxmediumdark = { cs = "gruvbox" },
  gruvboxlight = { cs = "gruvbox", bg = "light" },
  gruvboxmaterialdark = { cs = "gruvbox-material" },
  gruvboxmateriallight = { cs = "gruvbox-material", bg = "light" },

  catppuccinmocha = { cs = "catppuccin-mocha" },
  catppuccinmacchiato = { cs = "catppuccin-macchiato" },
  catppuccinfrappe = { cs = "catppuccin-frappe" },
  catppuccinfrapp = { cs = "catppuccin-frappe" },
  catppuccinlatte = { cs = "catppuccin-latte", bg = "light" },

  tokyonight = { cs = "tokyonight-night" },
  tokyonightstorm = { cs = "tokyonight-storm" },
  tokyonightmoon = { cs = "tokyonight-moon" },
  tokyonightlight = { cs = "tokyonight-day", bg = "light" },
  tokyonightday = { cs = "tokyonight-day", bg = "light" },

  kanagawawave = { cs = "kanagawa-wave" },
  kanagawadragon = { cs = "kanagawa-dragon" },
  kanagawalotus = { cs = "kanagawa-lotus", bg = "light" },

  rosepine = { cs = "rose-pine-main" },
  rospine = { cs = "rose-pine-main" },
  rosepinemoon = { cs = "rose-pine-moon" },
  rospinemoon = { cs = "rose-pine-moon" },
  rosepinedawn = { cs = "rose-pine-dawn", bg = "light" },
  rospinedawn = { cs = "rose-pine-dawn", bg = "light" },

  everforestdarkhard = { cs = "everforest", pre = everforest("hard") },
  everforestdarkmedium = { cs = "everforest", pre = everforest("medium") },
  everforestdarksoft = { cs = "everforest", pre = everforest("soft") },
  everforestlighthard = { cs = "everforest", bg = "light", pre = everforest("hard") },
  everforestlightmedium = { cs = "everforest", bg = "light", pre = everforest("medium") },
  everforestlightsoft = { cs = "everforest", bg = "light", pre = everforest("soft") },

  nord = { cs = "nord" },
  dracula = { cs = "dracula" },
  onedark = { cs = "onedark" },
  oxocarbondark = { cs = "oxocarbon" },
  ayudark = { cs = "ayu-dark" },
  ayumirage = { cs = "ayu-mirage" },
  ayulight = { cs = "ayu-light", bg = "light" },
}

-- ───────────── helpers ─────────────

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function read_palette()
  local s = read_file(palette_file)
  if not s then
    return nil
  end
  local p = {}
  for k, v in s:gmatch("(%w+)='(#%x%x%x%x%x%x)'") do
    p[k] = v:lower()
  end
  if not (p.background and p.foreground and p.color15) then
    return nil
  end
  return p
end

local function rgb(h)
  return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
end

-- blend color a towards b by t (0..1)
local function mix(a, b, t)
  local r1, g1, b1 = rgb(a)
  local r2, g2, b2 = rgb(b)
  local function m(x, y)
    return math.floor(x + (y - x) * t + 0.5)
  end
  return string.format("#%02x%02x%02x", m(r1, r2), m(g1, g2), m(b1, b2))
end

-- ───────────── apply ─────────────

local function apply_real(name)
  local key = (name or ""):lower():gsub("[^%w]", "")
  local entry = schemes[key]
  if not entry then
    return false
  end
  vim.o.background = entry.bg or "dark"
  if entry.pre then
    entry.pre()
  end
  return pcall(vim.cmd.colorscheme, entry.cs)
end

local function apply_base16()
  local p = read_palette()
  if not p then
    vim.notify("wallust palette not found: " .. palette_file, vim.log.levels.WARN)
    return
  end
  local bg, fg = p.background, p.foreground
  vim.cmd("highlight clear")
  require("mini.base16").setup({
    palette = {
      base00 = bg,
      base01 = mix(bg, fg, 0.07),
      base02 = mix(bg, fg, 0.15),
      base03 = mix(bg, fg, 0.40),
      base04 = mix(bg, fg, 0.65),
      base05 = fg,
      base06 = mix(fg, p.color15, 0.5),
      base07 = p.color15,
      base08 = p.color1,
      base09 = mix(p.color1, p.color3, 0.5),
      base0A = p.color3,
      base0B = p.color2,
      base0C = p.color6,
      base0D = p.color4,
      base0E = p.color5,
      base0F = p.color9,
    },
    use_cterm = true,
  })
  vim.g.colors_name = "wallust"
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "wallust", modeline = false })
end

-- lualine computes its "auto" theme once; rebuild it for the new colors
local function refresh_statusline()
  if package.loaded["lualine"] then
    local lualine = require("lualine")
    pcall(function()
      lualine.setup(lualine.get_config())
    end)
  end
end

local function apply()
  local name = (read_file(current_file) or ""):gsub("%s+$", "")
  if not apply_real(name) then
    apply_base16()
  end
  refresh_statusline()
end

local watching = false
local function watch()
  if watching then
    return
  end
  watching = true
  local dir = vim.fn.fnamemodify(palette_file, ":h")
  local fname = vim.fn.fnamemodify(palette_file, ":t")
  local event = vim.uv.new_fs_event()
  local timer = vim.uv.new_timer()
  event:start(dir, {}, function(err, changed)
    if err or changed ~= fname then
      return
    end
    -- wallust writes several files at once; wait a moment, then reload
    timer:stop()
    timer:start(200, 0, vim.schedule_wrap(function()
      apply()
      vim.cmd("redraw!")
    end))
  end)
end

return {
  { "nvim-mini/mini.base16", lazy = false, priority = 1000 },

  -- real colorschemes (catppuccin and tokyonight already come with LazyVim)
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "sainnhe/gruvbox-material", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "sainnhe/everforest", lazy = true },
  { "gbprod/nord.nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "navarasu/onedark.nvim", lazy = true },
  { "nyoom-engineering/oxocarbon.nvim", lazy = true },
  { "Shatur/neovim-ayu", lazy = true },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        apply()
        watch()
      end,
    },
  },
}
