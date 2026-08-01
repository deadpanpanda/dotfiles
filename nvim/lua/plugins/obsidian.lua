return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>",      desc = "Obsidian: search notes" },
    { "<leader>on", "<cmd>ObsidianNew<cr>",         desc = "Obsidian: new note" },
    { "<leader>od", "<cmd>ObsidianToday<cr>",       desc = "Obsidian: today's note" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>",   desc = "Obsidian: yesterday's note" },
    { "<leader>oT", "<cmd>ObsidianTomorrow<cr>",    desc = "Obsidian: tomorrow's note" },
    { "<leader>ow", "<cmd>ObsidianWorkspace<cr>",   desc = "Obsidian: switch workspace" },
    { "<leader>ot", "<cmd>ObsidianTemplate<cr>",    desc = "Obsidian: insert template" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>",   desc = "Obsidian: backlinks" },
    { "<leader>oa", "<cmd>ObsidianTags<cr>",        desc = "Obsidian: tags" },
    { "<leader>oO", "<cmd>ObsidianOpen<cr>",        desc = "Obsidian: open in app" },
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "/mnt/c/repos/obsidian",
      },
      {
        name = "work",
        path = "/mnt/c/repos/hq",
      },
    },

    -- New notes go in the same folder as the current buffer (matches your
    -- topic-folder layout: Work/, Personal/, Cheatsheets/, ...).
    new_notes_location = "current_dir",

    -- Use markdown-style links rather than [[wiki]] links.
    preferred_link_style = "markdown",

    -- Don't manage YAML frontmatter — your existing notes don't use it,
    -- and Obsidian app doesn't add it automatically either.
    disable_frontmatter = true,

    -- Match the Obsidian app's daily-notes core plugin settings.
    daily_notes = {
      folder = "Daily Notes",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      template = "Daily Notes.md",
    },

    -- Match the Obsidian app's templates plugin settings.
    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {},
    },

    -- You use blink.cmp, not nvim-cmp.
    completion = {
      nvim_cmp = false,
      blink = true,
      min_chars = 2,
    },

    -- Telescope is your installed picker.
    picker = {
      name = "telescope.nvim",
      note_mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
      tag_mappings = {
        tag_note = "<C-x>",
        insert_tag = "<C-l>",
      },
    },

    mappings = {
      -- Make `gf` follow markdown/wiki links inside the vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle checkboxes.
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- <CR>: follow link, or toggle checkbox if on one.
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },
  },
}
