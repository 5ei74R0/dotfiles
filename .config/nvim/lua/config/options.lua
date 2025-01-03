-- Appearance
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

-- Tab
vim.opt.expandtab = true  -- convert <tab> to spaces
vim.opt.shiftwidth = 2  -- length of <tab>
vim.opt.tabstop = 2  -- length of an indent

