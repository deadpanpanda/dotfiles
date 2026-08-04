-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.termguicolors = true
vim.opt.gdefault = true
-- Spell checking is left off globally on purpose. Setting it here turned it on
-- in code buffers too, where syntax rules confine it to comments and strings,
-- so every bit of jargon in a comment got a red undercurl. LazyVim's
-- `wrap_spell` autocmd already enables it for text, plaintex, typst, gitcommit
-- and markdown, which is where prose actually lives. Add filetypes to that
-- pattern list if something is missing rather than switching it on globally.
vim.opt.spelloptions = { "camel" }
vim.opt.list = true
vim.opt.title = true
vim.opt.foldlevelstart = 99
vim.opt.clipboard = "unnamedplus"
