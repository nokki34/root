-- nvim-treesitter `main` branch config.
--
-- Neovim 0.12 already bundles AND version-syncs these parsers + queries:
--   c, lua, markdown, markdown_inline, query, vim, vimdoc
-- Installing our own copies would shadow Neovim's and cause parser/query
-- mismatches (e.g. `Invalid field name "operator"`), so we only manage the
-- extra languages here and let Neovim handle the bundled ones.
local parsers = {
	"python",
	"javascript",
	"typescript",
	"go",
	"dockerfile",
	"zig",
}

require("nvim-treesitter").install(parsers)

-- Unlike the old `master` branch, `main` does not auto-enable highlighting.
-- Start treesitter per-buffer on FileType. (Neovim's own ftplugins already
-- do this for the bundled languages above.)
vim.api.nvim_create_autocmd("FileType", {
	pattern = parsers,
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
