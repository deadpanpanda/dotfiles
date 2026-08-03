return {
  {
    "kristijanhusak/vim-dadbod-ui",
    -- Deliberately left on LazyVim's default <leader>D.
    --
    -- This used to rebind the DB UI toggle to <leader>db, which collides with
    -- nvim-dap's Toggle Breakpoint. The collision was silent: dadbod won, and
    -- there was then no key bound to setting a breakpoint at all, which only
    -- surfaced when debugging Unreal C++.
    --
    -- The lang.sql extra's init already sets db_ui_use_nerd_fonts,
    -- db_ui_show_database_icon, the save locations and
    -- db_ui_execute_on_save = false, so there is nothing to override here.
  },
}
