return {
  {
    "kristijanhusak/vim-dadbod-ui",
    -- LazyVim's lang.sql extra binds <leader>D. Prefer <leader>db.
    -- The extra's init already sets db_ui_use_nerd_fonts and
    -- db_ui_show_database_icon, along with save locations and
    -- db_ui_execute_on_save = false, so it is left untouched here.
    keys = {
      { "<leader>D", false },
      { "<leader>db", "<cmd>DBUIToggle<CR>", desc = "Toggle DB UI" },
    },
  },
}
