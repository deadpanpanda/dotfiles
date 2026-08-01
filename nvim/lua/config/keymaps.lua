-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Reopen the dashboard ("home" screen)
vim.keymap.set("n", "<leader>h", function()
  Snacks.dashboard.open()
end, { desc = "Home (Dashboard)" })
