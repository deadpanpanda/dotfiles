-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ---------------------------------------------------------------------------
-- .NET build -> quickfix (the equivalent of Visual Studio's build + Error List)
-- Logic lives in lua/util/dotnet.lua; LSP setup is in lua/plugins/dotnet.lua.
--
--   <leader>cb      build the solution, errors only
--   :DotnetBuild    same
--   :DotnetBuild!   include warnings (this repo has ~7,000, so not the default)
-- ---------------------------------------------------------------------------

local function build_solution(include_warnings)
  local dotnet = require("util.dotnet")
  local sln = dotnet.find_solution()
  if not sln then
    vim.notify("dotnet build: no .sln found above the current file", vim.log.levels.ERROR)
    return
  end
  dotnet.build(sln, { warnings = include_warnings })
end

vim.api.nvim_create_user_command("DotnetBuild", function(o)
  build_solution(o.bang)
end, { bang = true, desc = "dotnet build solution into quickfix (! includes warnings)" })

-- ---------------------------------------------------------------------------
-- Unreal Engine build -> quickfix. Logic lives in lua/util/unreal.lua; clangd
-- setup is in lua/plugins/cpp.lua.
--
--   <leader>cb              build (dispatches, see below)
--   <leader>cg              regenerate compile_commands.json for clangd
--   :UnrealBuild            build the editor target, errors only
--   :UnrealBuild!           include warnings
--   :UnrealCompileCommands  regenerate the clangd compile database
--
-- Registered on Windows only: UnrealBuildTool drives MSVC and cannot run from
-- the WSL side of this shared config.
-- ---------------------------------------------------------------------------

if require("util.platform").is_windows then
  vim.api.nvim_create_user_command("UnrealBuild", function(o)
    require("util.unreal").build({ warnings = o.bang })
  end, { bang = true, desc = "Unreal build into quickfix (! includes warnings)" })

  vim.api.nvim_create_user_command("UnrealCompileCommands", function()
    require("util.unreal").compile_commands()
  end, { desc = "Regenerate compile_commands.json for clangd" })

  vim.keymap.set("n", "<leader>cg", function()
    require("util.unreal").compile_commands()
  end, { desc = "Unreal: regenerate compile database" })
end

-- <leader>cb builds whatever the current file actually belongs to. An Unreal
-- project is detected by a .uproject above the buffer; everything else falls
-- through to the .NET path, so this keeps working unchanged in work repos.
vim.keymap.set("n", "<leader>cb", function()
  local unreal = require("util.unreal")
  if require("util.platform").is_windows and unreal.find_project() then
    unreal.build({ warnings = false })
  else
    build_solution(false)
  end
end, { desc = "Build (Unreal or dotnet)" })
