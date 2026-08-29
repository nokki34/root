return {
    'nvim-telescope/telescope.nvim',
    -- v0.2.x is required with nvim-treesitter `main`: 0.1.8 called APIs the
    -- main rewrite removed (parsers.ft_to_lang, nvim-treesitter.configs) and
    -- threw on every preview. v0.2+ uses Neovim's own vim.treesitter APIs.
    tag = 'v0.2.2',
    dependencies = { 'nvim-lua/plenary.nvim' },
}
