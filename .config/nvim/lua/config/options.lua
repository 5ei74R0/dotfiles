-- Appearance
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.list = true
vim.opt.listchars = {
  space = '·',
  tab = '>-',
  trail = '~',
  extends = '>',
  precedes = '<',
  nbsp = '%'
}

-- Keymap
vim.keymap.set("v", ">", ">gv")  -- do not release selected lines after increasing/decreasing indents
vim.keymap.set("v", "<", "<gv")  -- do not release selected lines after increasing/decreasing indents

-- Tab
vim.opt.expandtab = true  -- convert <tab> to spaces
vim.opt.shiftwidth = 2  -- length of <tab>
vim.opt.tabstop = 2  -- length of an indent

-- Yank/Copy
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    if vim.v.event.operator == 'y' and vim.v.event.regname == '' then
      vim.fn.setreg('+', vim.fn.getreg('0'))
    end
  end,
  desc = 'Copy yanked text to system clipboard'
})

