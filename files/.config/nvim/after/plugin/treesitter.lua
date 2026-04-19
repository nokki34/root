require("nvim-treesitter").setup({
	ensure_installed = {
		"python",
		"javascript",
		"typescript",
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
