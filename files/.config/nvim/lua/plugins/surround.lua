return {
  "kylechui/nvim-surround",
  version = "*", -- Use for stability; omit to use latest
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({})
  end
}
