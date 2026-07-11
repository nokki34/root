return {
	"nvim-treesitter/nvim-treesitter",
	name = "nvim-treesitter",
	branch = "main", -- pin explicitly: the rewrite; different API from `master`
	lazy = false,
	build = ":TSUpdate",
}
