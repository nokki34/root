require("nokki34.remap")
require("nokki34.indent")
require("nokki34.cheatsheet")

vim.opt.number = true        -- Show absolute line number on the current line
vim.opt.relativenumber = true -- Show relative line numbers on all other lines
vim.opt.termguicolors = true -- Show all colors

-- go
vim.cmd([[
  autocmd FileType go setlocal tabstop=4 shiftwidth=4 expandtab
]])

print("Hello from nokki34")
