-- opencode.nvim — the plugin's recommended setup.
-- Only deviation: keymaps sit under <leader>a instead of the README's <C-a>,
-- <C-x> and `go`, which would shadow increment-number, visual-block and the
-- goto-byte motion respectively.
-- snacks identifies a terminal by cmd + cwd + env + v:count1 (Snacks.terminal.tid),
-- so start() and the toggle share these to hit one instance. Sharing the opts
-- table also keeps the float geometry identical when toggle has to recreate it.
-- Note: the cwd is part of that identity — see the caveat below.
local TERM_CMD = "opencode --port"
local TERM_OPTS = {
  win = {
    position = "float",
    width = 0.5,
    height = 0.5,
    border = "rounded",
    title = " opencode ",
    title_pos = "center",
    -- MUST stay false. ask() resolves the server first, and only then calls
    -- Context.new, which reads the *current* window. If starting the server
    -- focuses this float, context captures the terminal buffer instead of your
    -- code — opencode then has no idea what file you're in. Stock's
    -- `| wincmd p` exists for this reason.
    enter = false,
    keys = {
      -- snacks' own escape is `term_normal`: <esc> on a 200ms double-tap timer
      -- (snacks/terminal.lua:51). The first <esc> is passed through to
      -- opencode's TUI and only a second one inside that window calls
      -- stopinsert — too tight in practice, so you end up on <C-\><C-n>.
      -- This is a single unambiguous key instead. Merges with the snacks
      -- defaults rather than replacing them, so `q` and `gf` still work once
      -- you're in normal mode.
      term_hide = {
        "<C-q>",
        function(self)
          self:hide()
        end,
        mode = "t",
        desc = "Hide opencode",
      },
    },
  },
  auto_close = false,
}

return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    -- sudo-tee/opencode.nvim was trialled against this and dropped: its float is
    -- a pair of plain buffers it lays out itself, so it gets none of snacks'
    -- styling, and its quick-chat binding overwrites the visual selection with
    -- generated code rather than answering questions about it.
    --
    -- Both repos are named opencode.nvim and both ship a `lua/opencode.lua`, so
    -- only one can be on the runtimepath at a time. Re-adding the other means
    -- disabling this one.
    init = function()
      -- opencode edits files on disk; without this the buffers go stale.
      vim.o.autoread = true

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- Stock is `vsplit term://opencode --port | wincmd p` — a raw nvim
          -- terminal, so LazyVim's terminal keys don't apply to it. Routing
          -- through snacks gives <esc><esc> to normal mode, `q` to hide, and `gf`.
          start = function()
            -- This runs once per session, on the first opencode command, and is
            -- why that first <leader>aa flashes the float over ask()'s prompt.
            -- open() cannot be asked to stay hidden: it forces `show = false`
            -- while building the win, then calls terminal:show() itself before
            -- jobstart (snacks/terminal.lua:158-166). So let it show and put it
            -- straight back. open() returns after jobstart, so the job is
            -- already attached, and hide() is close({ buf = false }) — the
            -- buffer survives, the server keeps running, and <C-q> later shows
            -- this same instance rather than spawning a second one.
            require("snacks").terminal.open(TERM_CMD, TERM_OPTS):hide()
          end,
        },
      }
    end,
    keys = {
      { "<leader>a", "", desc = "+ai/opencode", mode = { "n", "x" } },
      {
        "<leader>aa",
        function() require("opencode").ask("@this: ") end,
        desc = "Ask opencode",
        mode = { "n", "x" },
      },
      {
        "<leader>ap",
        function() require("opencode").select() end,
        desc = "Select prompt/command/server",
        mode = { "n", "x" },
      },
      {
        "<leader>ah",
        -- focus() not toggle(): toggle() hides a visible float, which would leave
        -- no way to enter it now that it never takes focus itself. focus() enters
        -- it when you're outside, and hides it when you're already inside.
        function() require("snacks").terminal.focus(TERM_CMD, TERM_OPTS) end,
        desc = "Focus/hide opencode window",
      },
      {
        -- Same action as <leader>ah, on a single chord. This deliberately
        -- shadows builtin <C-q> (blockwise Visual, the duplicate of <C-v> that
        -- exists for terminals which eat <C-v>). <C-v> itself is untouched, so
        -- blockwise Visual is still available.
        "<C-q>",
        function() require("snacks").terminal.focus(TERM_CMD, TERM_OPTS) end,
        desc = "Focus/hide opencode window",
      },
      {
        "<leader>au",
        function() require("opencode").command("session.half.page.up") end,
        desc = "Scroll opencode up",
      },
      {
        "<leader>ai",
        function() require("opencode").command("session.half.page.down") end,
        desc = "Scroll opencode down",
      },
    },
  },

  -- The ask prompt is a snacks.win with filetype `opencode_ask`, and the
  -- plugin starts an in-process LSP on that buffer (opencode/config.lua:63)
  -- to serve its `@` mentions — @this, @diagnostics, @file and friends.
  -- blink then runs its *default* sources there too, which is where the noise
  -- comes from: `date~`/`uuid~`/`diso~` are friendly-snippets' "all" set, and
  -- buffer adds every word in the file. Restrict the filetype to opencode's
  -- own source only.
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          -- Not the stock `lsp` provider: that one declares
          -- `fallbacks = { 'buffer' }` (blink/cmp/config/sources.lua:58), so
          -- buffer words would still appear whenever opencode returns nothing.
          -- Same module, no fallback.
          opencode_ask = { "opencode_ask" },
        },
        providers = {
          opencode_ask = {
            name = "opencode",
            module = "blink.cmp.sources.lsp",
            -- Only offer anything once an `@` is being typed. Without this the
            -- menu opens on any keyword (min_keyword_length is 0), so a bare
            -- "d" still matched @diagnostics and made the prompt jitter.
            -- Matches an @ followed by non-space, anchored to the cursor, so
            -- it stays live while typing "@dia" but not after the mention is
            -- finished and you carry on writing the question.
            should_show_items = function(ctx)
              local before = ctx.line:sub(1, ctx.cursor[2])
              return before:match("@%S*$") ~= nil
            end,
          },
        },
      },
    },
  },
}
