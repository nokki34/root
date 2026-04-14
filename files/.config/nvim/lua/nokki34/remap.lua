vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set('v', '<leader>y', '"+y', {desc = "Copy to system clipboard"})
vim.keymap.set('n', '<leader>y', '"+yy', {desc = "Copy line to system clipboard"})
