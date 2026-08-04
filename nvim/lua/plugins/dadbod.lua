-- vim-dadbod-ui layout tweaks.
--
-- Two things the plugins do that are not configurable:
--
--  1. The query buffer opens with `vertical botright new`
--     (vim-dadbod-ui/autoload/db_ui/query.vim:69), so it adds a split rather
--     than reusing the current window - which leaves the LazyVim dashboard
--     sitting in the middle.
--  2. dadbod-ui runs plain `:DB ...` with no modifiers, so vim-dadbod falls
--     through to `pedit` (vim-dadbod/autoload/db.vim:545). That is a *preview*
--     window, which is why results appear as a full-width strip on the bottom
--     edge regardless of where the cursor was.
--
-- Both are fixed below with autocmds. Nothing here patches the plugins.

-- Where results (the .dbout buffer) should go:
--   "below" - beneath the query buffer, inside the right-hand column
--   "right" - its own third column, query and results side by side
--   "full"  - full height to the right of the drawer
local RESULTS_LAYOUT = "below"

-- Close the LazyVim dashboard when the DB UI opens.
local CLOSE_DASHBOARD = true

local dashboard_filetypes = {
  snacks_dashboard = true,
  dashboard = true,
  alpha = true,
  starter = true,
}

local function close_dashboard()
  if not CLOSE_DASHBOARD then
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      if dashboard_filetypes[ft] then
        -- Never close the last window.
        if #vim.api.nvim_list_wins() > 1 then
          pcall(vim.api.nvim_win_close, win, false)
        end
      end
    end
  end
end

-- Find the window holding the dadbod-ui query buffer, if there is one.
local function find_query_win(exclude)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= exclude and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ok, is_dbui = pcall(function()
        return vim.b[buf].dbui_db_key_name ~= nil
      end)
      if ok and is_dbui and vim.bo[buf].filetype ~= "dbout" then
        return win
      end
    end
  end
  return nil
end

-- Every query writes its own .dbout buffer. They are kept, so switching
-- between result sets is just switching buffers in the results window -
-- the DBeaver "result tabs" model.
local function dbout_buffers()
  local out = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dbout" then
      table.insert(out, buf)
    end
  end
  table.sort(out)
  return out
end

local function cycle_result(step)
  local bufs = dbout_buffers()
  if #bufs < 2 then
    vim.notify("dadbod: only one result set", vim.log.levels.INFO)
    return
  end
  local cur = vim.api.nvim_get_current_buf()
  local idx = 1
  for i, b in ipairs(bufs) do
    if b == cur then
      idx = i
      break
    end
  end
  local nxt = bufs[((idx - 1 + step) % #bufs) + 1]
  vim.api.nvim_set_current_buf(nxt)
  vim.notify(
    ("dadbod: result %d/%d"):format(((idx - 1 + step) % #bufs) + 1, #bufs),
    vim.log.levels.INFO
  )
end

-- Close the current result set. If others remain, show the next one instead of
-- closing the pane, so the layout stays put.
local function close_result()
  local cur = vim.api.nvim_get_current_buf()
  local bufs = dbout_buffers()
  if #bufs > 1 then
    cycle_result(1)
    pcall(vim.api.nvim_buf_delete, cur, { force = true })
  else
    pcall(vim.api.nvim_buf_delete, cur, { force = true })
  end
end

local function close_all_results()
  for _, buf in ipairs(dbout_buffers()) do
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

function set_dbout_keymaps(bufnr)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, desc = desc })
  end
  -- Buffer-local on purpose: <leader>d* is nvim-dap's prefix, and these only
  -- make sense inside a results buffer anyway.
  map("]r", function()
    cycle_result(1)
  end, "Next result set")
  map("[r", function()
    cycle_result(-1)
  end, "Previous result set")
  map("q", close_result, "Close this result set")
  map("Q", close_all_results, "Close all result sets")
end

local function place_results(bufnr)
  -- NOTE: `pedit` opens the preview window without moving the cursor into it,
  -- so the current window is NOT the results window here. Resolve it from the
  -- buffer instead.
  local dbout_win = vim.fn.bufwinid(bufnr)
  if dbout_win == -1 or not vim.api.nvim_win_is_valid(dbout_win) then
    return
  end

  -- Do NOT clear `previewwindow` here. `pedit` uses that flag to find an
  -- existing results window and reuse it; clearing it makes every query open
  -- yet another split until the screen is full of them.
  vim.wo[dbout_win].winfixheight = false

  -- vim-dadbod sets `bufhidden=delete` and `nobuflisted` on result buffers
  -- (vim-dadbod/autoload/db.vim:410), so each result is destroyed as soon as
  -- the next one replaces it in the window. Keep them instead, so they behave
  -- like DBeaver result tabs and appear in the bufferline.
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].buflisted = true

  set_dbout_keymaps(bufnr)

  -- One results pane: if earlier queries left extra results windows around,
  -- close all but this one. The buffers survive - only windows close.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= dbout_win and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "dbout" and #vim.api.nvim_list_wins() > 1 then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  end

  if RESULTS_LAYOUT == "full" then
    vim.api.nvim_win_call(dbout_win, function()
      vim.cmd("wincmd L")
    end)
    return
  end

  local query_win = find_query_win(dbout_win)
  if not query_win then
    -- No query buffer (e.g. plain :DB from a normal file). Right column is the
    -- least intrusive fallback.
    vim.api.nvim_win_call(dbout_win, function()
      vim.cmd("wincmd L")
    end)
    return
  end

  pcall(vim.fn.win_splitmove, dbout_win, query_win, {
    vertical = RESULTS_LAYOUT == "right",
    rightbelow = true,
  })

  if RESULTS_LAYOUT == "below" then
    -- Give results a bit more room than the default half.
    local total = vim.api.nvim_win_get_height(query_win) + vim.api.nvim_win_get_height(dbout_win)
    pcall(vim.api.nvim_win_set_height, dbout_win, math.floor(total * 0.6))
  end
end

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
    init = function()
      -- IMPORTANT: lazy.nvim OVERWRITES `init` rather than merging it, so this
      -- function replaces the one in LazyVim's lang.sql extra. Everything that
      -- extra sets must be repeated here or it is silently lost - which already
      -- happened once: db_ui_save_location fell back to ~/.local/share/db_ui
      -- (connections vanished) and db_ui_execute_on_save reverted to 1, which
      -- re-enabled running queries on every :w.
      local data_path = vim.fn.stdpath("data")

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true
      vim.g.db_ui_execute_on_save = false

      -- Ours.
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40

      local group = vim.api.nvim_create_augroup("dadbod_layout", { clear = true })

      -- Results window: reposition once it exists.
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "dbout",
        callback = function(args)
          vim.schedule(function()
            place_results(args.buf)
          end)
        end,
      })

      -- The drawer's ftplugin maps <C-j>/<C-k> buffer-locally to last/first
      -- sibling, shadowing LazyVim's window navigation in that one window.
      -- Hand them back to window movement; J/K still do sibling jumps.
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "dbui",
        callback = function(args)
          -- Deferred: the ftplugin sets its mappings on this same event.
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(args.buf) then
              return
            end
            vim.keymap.set("n", "<C-j>", "<C-w>j", {
              buffer = args.buf,
              desc = "Go to Lower Window",
            })
            vim.keymap.set("n", "<C-k>", "<C-w>k", {
              buffer = args.buf,
              desc = "Go to Upper Window",
            })
          end)
        end,
      })

      -- Dashboard: close it once the DB UI is on screen.
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "dbui", "sql" },
        callback = function()
          vim.schedule(close_dashboard)
        end,
      })
    end,
  },
}
