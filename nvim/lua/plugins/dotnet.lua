-- C# / .NET support.
--
-- Deliberately does NOT use `lazyvim.plugins.extras.lang.dotnet`, because that
-- extra configures OmniSharp, which does not cope with large solutions. This
-- uses the real Roslyn language server (the same engine as Visual Studio and
-- the VS Code C# Dev Kit) via nvim-lspconfig's built-in `roslyn_ls` config.
--
-- The server is not available through Mason (its NuGet package is not a valid
-- dotnet tool), so it is installed manually to:
--   ~/.local/share/roslyn-language-server/
-- and symlinked onto PATH as ~/.local/bin/Microsoft.CodeAnalysis.LanguageServer
-- It needs the .NET 10 runtime, installed side-by-side in ~/.dotnet.

local server_bin = "Microsoft.CodeAnalysis.LanguageServer"
local log_dir = vim.fn.stdpath("state") .. "/roslyn_ls/log"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c_sharp" } },
  },

  -- NOTE ON FORMATTING — deliberately no csharpier here.
  --
  -- csharpier is installed via Mason and works, but it is an *opinionated*
  -- formatter that disagrees with how this repo is written: `csharpier check`
  -- reports it would rewrite 2,800 of 3,135 files. Wiring it to `cs` with
  -- LazyVim's format-on-save would turn every PR into an unreviewable diff.
  --
  -- Instead we fall through to LSP formatting, which is Roslyn's own formatter
  -- -- the same engine Visual Studio uses, honouring .editorconfig. Verified to
  -- produce ZERO edits on already-committed files, so saving is safe.
  -- `<leader>cf` formats; it just routes to roslyn_ls rather than csharpier.
  --
  -- If the team ever adopts csharpier repo-wide, add:
  --   formatters_by_ft = { cs = { "csharpier" } }

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        roslyn_ls = {
          -- Not in the Mason registry mapping; we manage the binary ourselves.
          mason = false,

          -- `--logLevel` and `--extensionLogDirectory` are REQUIRED by the
          -- server. lspconfig's default cmd omits them, so the server would
          -- exit immediately on startup. Do not drop these.
          cmd = {
            server_bin,
            "--logLevel",
            "Warning",
            "--extensionLogDirectory",
            log_dir,
            "--stdio",
          },

          -- This repo has a nested single-project solution
          -- (src/Pairtree.Control/Pairtree.Control.sln) inside the real one
          -- (src/PairtreeV2.sln). lspconfig's default root_dir stops at the
          -- *nearest* .sln, which would start a second server that can only
          -- see one project. Prefer the OUTERMOST solution instead so the
          -- whole solution is loaded once.
          root_dir = function(bufnr, cb)
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if bufname == "" or bufname:find("[/\\]MetadataAsSource[/\\]") then
              return -- let decompiled/unnamed buffers reuse the running client
            end

            local outermost = nil
            local dir = vim.fs.dirname(bufname)
            for parent in vim.fs.parents(bufname) do
              dir = parent
              local found = vim.fn.globpath(dir, "*.sln", false, true)
              vim.list_extend(found, vim.fn.globpath(dir, "*.slnx", false, true))
              if #found > 0 then
                outermost = dir
              end
              -- stop climbing at the repo root
              if vim.uv.fs_stat(dir .. "/.git") then
                break
              end
            end

            if outermost then
              cb(outermost)
            end
          end,

          settings = {
            -- Full-solution analysis on ~3,200 files / ~267k LOC keeps cores
            -- busy and delays first diagnostics. `openFiles` is far more
            -- responsive; switch to "fullSolution" if you want project-wide
            -- diagnostics without building.
            ["csharp|background_analysis"] = {
              dotnet_analyzer_diagnostics_scope = "openFiles",
              dotnet_compiler_diagnostics_scope = "openFiles",
            },
            ["csharp|code_lens"] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
      },
    },
  },
}
