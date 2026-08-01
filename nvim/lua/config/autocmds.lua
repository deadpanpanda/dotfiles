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

vim.keymap.set("n", "<leader>cb", function()
  build_solution(false)
end, { desc = "Build solution (dotnet)" })
