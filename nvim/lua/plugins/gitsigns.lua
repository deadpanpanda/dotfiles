return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- "eol", "overlay", or "right_align"
      delay = 200, -- ms before blame appears (default 1000)
    },
    current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
  },
}
