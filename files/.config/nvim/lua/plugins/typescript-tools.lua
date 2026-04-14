return {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {
    settings = {
      tsserver_plugins = {},
      tsserver = {
        -- 👇 THIS controls import style
        preferences = {
          importModuleSpecifierPreference = "relative",
        },
      },
    },
  },
}  
