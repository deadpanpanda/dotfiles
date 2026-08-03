-- Debugging Unreal C++ from nvim.
--
-- Two adapters, because neither is clearly right and they are worth comparing:
--
--   cppvsdbg  vsdbg.exe, shipped inside Mason's cpptools package. This is the
--             SAME debug engine Visual Studio uses, so it reads MSVC PDBs
--             properly and copes with Unreal-sized binaries. Best results.
--             LICENSING: Microsoft's terms permit vsdbg only with Visual
--             Studio and VS Code. Driving it from nvim is outside those terms.
--             Enabled here as a deliberate, informed choice for this project.
--
--   codelldb  LLDB. Installed already by the LazyVim clangd extra. On Windows
--             its MSVC PDB support is partial, so expect missing locals or
--             unresolved breakpoints. Kept as a comparison point.
--
-- Unreal's normal workflow is ATTACH, not launch: start the editor, hit Play
-- In Editor, then attach and break on your code. Launch is provided too, for
-- debugging startup itself.
--
-- Windows only. UnrealBuildTool and vsdbg both need the MSVC toolchain.

local platform = require("util.platform")

if not platform.is_windows then
  return {}
end

local vsdbg = vim.fs.joinpath(
  vim.fn.stdpath("data"),
  "mason",
  "packages",
  "cpptools",
  "extension",
  "debugAdapters",
  "vsdbg",
  "bin",
  "vsdbg.exe"
)

--- Resolve the project and engine at the moment you start debugging, rather
--- than at startup, so this works from whichever .uproject you are inside.
local function unreal()
  local u = require("util.unreal")
  local uproject = u.find_project()
  if not uproject then
    error("No .uproject found above the current file")
  end
  return uproject, u.engine_root(uproject)
end

local function editor_exe()
  local _, engine = unreal()
  return vim.fs.joinpath(engine, "Engine", "Binaries", "Win64", "UnrealEditor.exe")
end

local function uproject_path()
  local uproject = unreal()
  return uproject
end

return {
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = { ensure_installed = { "cpptools" } },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")

      -- vsdbg speaks DAP directly when given --interpreter=vscode.
      dap.adapters.cppvsdbg = {
        id = "cppvsdbg",
        type = "executable",
        command = vsdbg,
        args = { "--interpreter=vscode" },
        -- Without this, nvim can exit leaving vsdbg orphaned and holding the
        -- debuggee, which then blocks the next build from writing the DLL.
        options = { detached = false },
      }

      local unreal_configs = {
        {
          name = "Unreal: attach to running editor (vsdbg)",
          type = "cppvsdbg",
          request = "attach",
          processId = function()
            return require("dap.utils").pick_process({ filter = "UnrealEditor" })
          end,
        },
        {
          name = "Unreal: launch editor with project (vsdbg)",
          type = "cppvsdbg",
          request = "launch",
          program = editor_exe,
          args = function()
            return { uproject_path() }
          end,
          cwd = function()
            return vim.fs.dirname(uproject_path())
          end,
          stopAtEntry = false,
          console = "integratedTerminal",
        },
        {
          name = "Unreal: attach to running editor (codelldb, experimental)",
          type = "codelldb",
          request = "attach",
          pid = function()
            return require("dap.utils").pick_process({ filter = "UnrealEditor" })
          end,
          cwd = "${workspaceFolder}",
        },
      }

      -- The clangd extra already populated these with generic launch/attach
      -- entries. Put the Unreal ones first rather than replacing them.
      for _, ft in ipairs({ "c", "cpp" }) do
        local existing = dap.configurations[ft] or {}
        local merged = vim.deepcopy(unreal_configs)
        vim.list_extend(merged, existing)
        dap.configurations[ft] = merged
      end
    end,
  },
}
