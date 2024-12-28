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
vim.opt.expandtab = true  -- converrt <tab> to spaces
vim.opt.shiftwidth = 2  -- <tab> would be converted to 2 spaces
vim.opt.tabstop = 2  -- length of <tab>

