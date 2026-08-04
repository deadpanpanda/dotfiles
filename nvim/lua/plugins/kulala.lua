return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Highlighting for the .http buffer itself comes from kulala's own
    -- `kulala_http` parser, which it fetches and builds on demand and registers
    -- over the generic `http` one. These are the languages its injections.scm
    -- pulls into request bodies, scripts and jq filters; without them those
    -- regions fall back to flat text. json/xml/lua/typescript/javascript are
    -- already installed by other extras, listed here so the set is explicit.
    opts = {
      ensure_installed = {
        "comment",
        "graphql",
        "javascript",
        "jq",
        "json",
        "lua",
        "typescript",
        "xml",
      },
    },
  },

  {
    "mistweaverco/kulala.nvim",
    -- Terminal replacement for the Postman desktop client. Requests live in
    -- plain .http files, so collections can sit in the repo they belong to.
    -- Postman collections come in via :lua require("kulala").import("postman")
    -- from a buffer holding the exported Collection v2.1 JSON.
    --
    -- Needs tree-sitter-cli on PATH to build the http parser. Installed at
    -- ~/.local/bin/tree-sitter (npm -g --prefix ~/.local tree-sitter-cli).
    ft = { "http", "rest" },
    -- The upstream spec also lists javascript and lua so external request
    -- scripts get the LSP. Skipped here: those files are only ever run from an
    -- .http buffer, which has already loaded kulala, and it would otherwise
    -- pull kulala in on every lua config file.
    keys = {
      { "<leader>R", "", desc = "+rest (kulala)" },
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
      { "<leader>Re", desc = "Select environment" },
    },
    ---@module "kulala"
    ---@type kulala.Config
    opts = {
      -- Full documented keymap set rather than send-only. <leader>R is free in
      -- LazyVim; the ones that matter day to day are Rs send, Ra send all,
      -- Re environment, Rr replay last, Ri inspect the generated curl.
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",
      -- Keymaps inside the response window (q to close, jump between panes).
      kulala_keymaps = true,

      -- Response opens beside the request, not over it.
      ui = {
        display_mode = "split",
        split_direction = "right",
        default_view = "body",
      },

      -- Environments come from http-client.env.json / http-client.private.env.json
      -- next to the .http file, same layout Postman environments export into.
      -- "b" keeps a selected env scoped to the buffer so two collections open at
      -- once don't fight over it.
      environment_scope = "b",
    },
  },
}
