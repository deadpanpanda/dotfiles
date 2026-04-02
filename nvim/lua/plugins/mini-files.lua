return {
  "nvim-mini/mini.files",
  dependencies = { "nvim-mini/mini.icons" },
  keys = {
    { "<leader>fm", desc = "Toggle mini.files" },
  },
  config = function()
    require("mini.files").setup({
      mappings = {
        go_in = "l",
        go_in_plus = "L",
        go_out = "h",
        go_out_plus = "H",
        synchronize = "=",
        reset = "<BS>",
      },
      windows = {
        preview = true,
        width_focus = 30,
        width_preview = 40,
      },
      options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      },
    })

    -- Toggle mini.files at current file
    vim.keymap.set("n", "<leader>fm", function()
      if not MiniFiles.close() then
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      end
    end, { desc = "Toggle mini.files" })

    -- Dotfile toggle
    local show_dotfiles = true
    local filter_show = function()
      return true
    end
    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, ".")
    end

    local toggle_dotfiles = function()
      show_dotfiles = not show_dotfiles
      local filter = show_dotfiles and filter_show or filter_hide
      MiniFiles.refresh({ content = { filter = filter } })
    end

    -- Split helpers
    local map_split = function(buf_id, lhs, direction)
      local rhs = function()
        local entry = MiniFiles.get_fs_entry()
        if entry == nil or entry.fs_type ~= "file" then
          return
        end
        MiniFiles.close()
        if direction == "horizontal" then
          vim.cmd("split " .. vim.fn.fnameescape(entry.path))
        elseif direction == "vertical" then
          vim.cmd("vsplit " .. vim.fn.fnameescape(entry.path))
        elseif direction == "tab" then
          vim.cmd("tabedit " .. vim.fn.fnameescape(entry.path))
        end
      end
      vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = "Open in " .. direction })
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local buf_id = args.data.buf_id
        map_split(buf_id, "<C-w>s", "horizontal")
        map_split(buf_id, "<C-w>v", "vertical")
        map_split(buf_id, "<C-w>t", "tab")
        vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toggle dotfiles" })
      end,
    })
  end,
}
