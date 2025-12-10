local function enable_transparency()
  vim.api.nvim_set_hl(0, "normal", { bg = "none" })
end
return {
  {
    "cpplain/flexoki.nvim",
    config = function()
      vim.cmd.colorscheme "flexoki"
      enable_transparency()
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      theme = 'flexoki',
    },
  },
}
