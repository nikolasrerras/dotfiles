return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,

  config = function()
    require("catppuccin").setup({
      flavour = "mocha",

      color_overrides = {
        mocha = {
          peach = "#f5a97f",
        },
      },

      integrations = {
        treesitter = true,
        native_lsp = {
          enabled = true,
        },
        telescope = {
          enabled = true,
        },
        cmp = true,
        gitsigns = true,
        which_key = true,
      },
    })

    vim.cmd.colorscheme("catppuccin")
  end,
}
