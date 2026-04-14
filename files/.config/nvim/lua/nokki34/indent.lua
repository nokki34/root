vim.api.nvim_create_autocmd("FileType", {
  pattern = "typescript",
  callback = function()
    vim.opt_local.tabstop = 2       -- Number of spaces a <Tab> counts for
    vim.opt_local.shiftwidth = 2    -- Number of spaces used for each indent
    vim.opt_local.expandtab = true  -- Convert tabs to spaces
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.opt_local.tabstop = 2       -- Number of spaces a <Tab> counts for
    vim.opt_local.shiftwidth = 2    -- Number of spaces used for each indent
    vim.opt_local.expandtab = true  -- Convert tabs to spaces
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sh",
  callback = function()
    vim.opt_local.tabstop = 2       -- Number of spaces a <Tab> counts for
    vim.opt_local.shiftwidth = 2    -- Number of spaces used for each indent
    vim.opt_local.expandtab = true  -- Convert tabs to spaces
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "zsh",
  callback = function()
    vim.opt_local.tabstop = 2       -- Number of spaces a <Tab> counts for
    vim.opt_local.shiftwidth = 2    -- Number of spaces used for each indent
    vim.opt_local.expandtab = true  -- Convert tabs to spaces
  end,
})

