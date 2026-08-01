return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  opts = function(_, opts)
    local ok, _ = pcall(require, "telescope")
    if ok then
      require("telescope").load_extension("fzf")
    end
  end,
}
