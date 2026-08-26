-- Curated cheatsheet of my own shortcuts. Toggle with <leader>?
-- Hand-maintained: when you add a map you actually want to remember, add it here.
local M = {}

local lines = {
  "  MY SHORTCUTS                         press  q / <Esc>  to close",
  "",
  "  GIT  (fugitive)",
  "    <leader>gs     status",
  "    <leader>gb     new branch (checkout -b)",
  "",
  "  DIFF / MR REVIEW  (diffview)",
  "    <leader>gd     open diff (working tree)",
  "    <leader>gD     close diffview",
  "    <leader>gh     file history (current file)",
  "    <leader>gH     repo history",
  "    :DiffviewOpen main...HEAD    review a branch/MR vs main",
  "",
  "  HUNKS  (gitsigns)",
  "    ]c   [c        next / prev hunk",
  "    <leader>hs hr  stage / reset hunk",
  "    <leader>hp     preview hunk",
  "    <leader>hb     blame line",
  "    <leader>tb     toggle line blame",
  "",
  "  FIND  (telescope)",
  "    <leader>pf     find files            <C-p>        git files",
  "    <leader>ps     live grep (no specs)  <leader>psa  live grep all",
  "",
  "  HARPOON",
  "    <leader>a      add file              <C-e>        menu",
  "    <leader>1..4   jump to file",
  "",
  "  MISC",
  "    <leader>pv     file explorer (netrw)",
  "    <leader>u      undotree",
  "    <leader>y      yank to system clipboard",
}

function M.open()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = width + 4
  local height = #lines

  local ui = vim.api.nvim_list_uis()[1]
  local total_w = ui and ui.width or vim.o.columns
  local total_h = ui and ui.height or vim.o.lines

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((total_h - height) / 2),
    col = math.floor((total_w - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = false

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

vim.keymap.set("n", "<leader>?", M.open, { desc = "Cheatsheet: my shortcuts" })

return M
