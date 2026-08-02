-- C / C++ support, tuned for Unreal Engine.
--
-- The bulk of the setup comes from `lazyvim.plugins.extras.lang.clangd`
-- (enabled in lazyvim.json), which wires up clangd, clangd_extensions,
-- clang-format and a codelldb DAP config. This file only overrides the
-- handful of things that extra gets wrong for Unreal.
--
-- clangd is driven entirely by `compile_commands.json`. Unreal does not ship
-- one; UnrealBuildTool generates it on demand. See lua/util/unreal.lua and
-- `:UnrealCompileCommands`. Without that file you get syntax highlighting and
-- nothing else, so generate it before expecting completion to work.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The extra only asks for "cpp". Unreal builds a fair amount of plain C
    -- in ThirdParty, and .ini/.cs files show up constantly in the tree.
    opts = { ensure_installed = { "c", "cpp", "c_sharp" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          -- Root at the Unreal project directory. `.uproject` sits next to
          -- the generated compile_commands.json, and matching on it means
          -- clangd roots correctly even before the database exists (when it
          -- would otherwise climb to `.git` and index the wrong tree).
          root_markers = {
            ".uproject",
            "compile_commands.json",
            "compile_flags.txt",
            ".clangd",
            "Makefile",
            "meson.build",
            "build.ninja",
            ".git",
          },

          cmd = {
            "clangd",
            "--background-index",

            -- CRITICAL for Unreal. The extra defaults to `iwyu`, which makes
            -- clangd auto-insert #includes as you accept completions. Unreal
            -- requires "Foo.generated.h" to be the LAST include in a header,
            -- and UnrealHeaderTool hard-errors if anything follows it. iwyu
            -- cheerfully inserts includes after it and breaks the build.
            "--header-insertion=never",

            -- clang-tidy is deliberately NOT enabled here (the extra turns it
            -- on). A single Unreal .cpp pulls in thousands of engine headers,
            -- so tidy turns every keystroke into a multi-second stall, and
            -- nearly everything it flags is in engine code you do not own.
            -- Add "--clang-tidy" back if you use this config for normal C++.

            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
      },
    },
  },
}
