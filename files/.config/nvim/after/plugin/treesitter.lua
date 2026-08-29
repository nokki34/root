-- nvim-treesitter `main` branch (the rewrite). Its API has nothing in common
-- with `master`: there is no `nvim-treesitter.configs`, no `ensure_installed`,
-- no `auto_install`, and no highlight module -- highlighting is Neovim's job.
--
-- Neovim 0.12 already bundles AND version-syncs these parsers + queries:
--   c, lua, markdown, markdown_inline, query, vim, vimdoc
-- We deliberately do NOT install those. Our copies would sit earlier on
-- 'runtimepath' and shadow Neovim's, and the two then drift apart on every
-- Neovim upgrade.
-- `main` builds parsers with the tree-sitter CLI (>=0.26.1, from a package
-- manager, NOT npm). Without it every :TSInstall fails, but Neovim's bundled
-- parsers keep working, so the breakage is silent -- say so loudly instead.
if vim.fn.executable("tree-sitter") == 0 then
	vim.notify(
		"nvim-treesitter (main) needs the tree-sitter CLI to build parsers.\n"
			.. "  Arch:  sudo pacman -S tree-sitter-cli\n"
			.. "  macOS: brew install tree-sitter",
		vim.log.levels.WARN
	)
end

-- lazy rewrites lazy-lock.json to match what is actually checked out, so a
-- stale `master` install survives deploying a `main` lockfile. Bail out with
-- something readable instead of a stack trace at every startup.
local ok, ts = pcall(require, "nvim-treesitter")
if not ok or type(ts.install) ~= "function" then
	vim.notify(
		"nvim-treesitter is still on `master`; this config needs `main`.\n"
			.. "  Run :Lazy update nvim-treesitter (or :Lazy sync), then restart.",
		vim.log.levels.WARN
	)
	return
end

ts.setup()

ts.install({
	"python",
	"javascript",
	"typescript",
	"tsx",
	"go",
	"dockerfile",
})

-- `main` does not turn highlighting on for you. Start it for any filetype that
-- actually has a parser, whether bundled with Neovim or installed above.
-- Neovim's own ftplugins already do this for markdown/lua/query, hence the
-- `active` guard; vim, vimdoc and c have no such ftplugin, so they need this.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local lang = vim.treesitter.language.get_lang(ev.match)
		if not lang or vim.treesitter.highlighter.active[ev.buf] then
			return
		end
		if pcall(vim.treesitter.language.add, lang) then
			pcall(vim.treesitter.start, ev.buf, lang)
		end
	end,
})
