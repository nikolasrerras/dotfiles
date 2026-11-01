-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- vim.api.nvim_create_autocmd("ColorScheme", {
local function apply_wallust()
  local ok, wallust = pcall(require, "wallust_colors")
  if not ok then
    return
  end

  local hl = vim.api.nvim_set_hl
  hl(0, "Normal", { bg = "none", fg = wallust.foreground })
  hl(0, "NormalNC", { bg = "none", fg = wallust.foreground })
  hl(0, "NormalFloat", { bg = "NONE" })
  hl(0, "SignColumn", { bg = "NONE" })
  hl(0, "EndOfBuffer", { bg = "NONE" })
  hl(0, "String", { fg = wallust.color14 })
  hl(0, "Comment", { fg = wallust.color8, italic = true })
  hl(0, "Keyword", { fg = wallust.color1, bold = true })
  hl(0, "Function", { fg = wallust.color4 })
end

apply_wallust()

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = apply_wallust,
})
