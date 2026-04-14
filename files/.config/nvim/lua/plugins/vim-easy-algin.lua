return {
  'junegunn/vim-easy-align',
  keys = {
    { 'ga', mode = { 'n', 'x' }, desc = 'EasyAlign' },
  },
  init = function()
    -- Visual mode: ga= to align by `=`
    vim.cmd [[xmap ga= <Plug>(EasyAlign)=]]
    -- Normal mode: ga=ip to align a paragraph by `=`
    vim.cmd [[nmap ga= <Plug>(EasyAlign)=ip]]
  end,
}
