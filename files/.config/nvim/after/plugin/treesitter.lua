require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"python",
		"javascript",
		"typescript",
		"tsx",
		"go",
		"lua",
		"vim",
		"vimdoc",
		"query",
		"markdown",
		"markdown_inline",
		"dockerfile",
	},
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
	},
})
