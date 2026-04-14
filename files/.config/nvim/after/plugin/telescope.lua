require("telescope").setup({
  extensions = {
    project = {
      base_dirs = {},
      hidden_files = false,
      theme = "dropdown",
      order_by = "asc",
      search_by = "title",
      sync_with_nvim_tree = true,
    },
  },
})


local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>ps', function()
	require('telescope.builtin').live_grep({
		glob_pattern = "!*.spec.ts"
	})
end)
vim.keymap.set('n', '<leader>psa', function()
	require('telescope.builtin').live_grep()
end)
