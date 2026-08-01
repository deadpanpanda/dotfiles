-- .NET debugging with netcoredbg (Samsung, MIT).
--
-- Visual Studio and VS Code use `vsdbg`, which Microsoft licenses ONLY for use
-- with their own products, so it cannot legally be used from Neovim.
-- netcoredbg is the FOSS alternative: breakpoints (incl. conditional), stepping,
-- locals/watches, call stack, and attach-to-process. No Hot Reload / EnC.
--
-- Requires lazyvim.plugins.extras.dap.core (enabled in lazyvim.json), which
-- brings nvim-dap, dap-ui, virtual-text and the <leader>d* keymaps.
--
--   <leader>dn   pick a project -> BUILD it -> debug it   (the F5 equivalent)
--   <leader>dA   attach to an already-running .NET process
--   <leader>dc   launch a pre-built project WITHOUT building (fast re-run)
--   <leader>db   toggle breakpoint      <leader>du  toggle debug UI
--
-- Why two launch paths: nvim-dap has no `preLaunchTask`, so it will happily run
-- a stale DLL -- a genuinely confusing failure mode. <leader>dn always builds
-- first. <leader>dc skips the build for when you know the binary is current.

local function netcoredbg_cmd()
  local mason = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "netcoredbg")
  if vim.uv.fs_stat(mason) then
    return mason
  end
  return vim.fn.exepath("netcoredbg")
end

--- Turn a project from util.dotnet into a netcoredbg launch configuration.
local function to_config(p)
  local dotnet = require("util.dotnet")
  local env = {}

  -- PAIRTREE_* vars first: these projects throw ConfigurationException at
  -- startup without them (JWT, DB_CONN, ...). See util.dotnet.env_file.
  local env_path = dotnet.env_file()
  if env_path then
    env = dotnet.load_env(env_path)
  end

  -- launchSettings' environmentVariables win over the env file.
  for k, v in pairs(p.env or {}) do
    env[k] = v
  end
  -- launchSettings' applicationUrl is what ASPNETCORE_URLS does at runtime.
  if p.url and p.url ~= "" then
    env.ASPNETCORE_URLS = p.url
  end
  return {
    type = "netcoredbg",
    name = p.name .. (p.url and ("  (" .. p.url .. ")") or ""),
    request = "launch",
    program = p.dll,
    cwd = p.dir, -- these projects call Directory.GetCurrentDirectory() for appsettings
    env = vim.tbl_isempty(env) and nil or env,
    stopAtEntry = false,
    console = "internalConsole",
  }
end

local function attach_config()
  return {
    type = "netcoredbg",
    name = "Attach to .NET process",
    request = "attach",
    processId = function()
      return require("dap.utils").pick_process({
        -- The interesting processes are `dotnet <proj>.dll` and apphost binaries.
        filter = function(proc)
          return proc.name ~= nil
            and (proc.name:match("[Dd]otnet") ~= nil or proc.name:match("Pairtree") ~= nil)
        end,
      })
    end,
  }
end

--- Register the adapter and rebuild dap.configurations.cs.
---
--- Idempotent and cheap, and called from several places on purpose. lazy.nvim
--- emits its `User LazyLoad` event via vim.schedule, i.e. AFTER the key handler
--- that triggered the load has already run -- so relying on that event alone
--- would race with <leader>dc calling dap.continue() before the adapter exists.
--- Verified: the event genuinely fires late.
local function ensure_dap()
  local dap = require("dap")

  dap.adapters.netcoredbg = {
    type = "executable",
    command = netcoredbg_cmd(),
    args = { "--interpreter=vscode" },
    options = { detached = false },
  }

  -- One entry per runnable project, replacing the single generic
  -- "NetCoreDbg: Launch" entry that mason-nvim-dap auto-generates.
  local configs = {}
  for _, p in ipairs(require("util.dotnet").runnable_projects()) do
    configs[#configs + 1] = to_config(p)
  end
  configs[#configs + 1] = attach_config()
  dap.configurations.cs = configs

  return dap
end

local function pick_build_and_debug()
  local dap = ensure_dap()
  local dotnet = require("util.dotnet")
  local projects = dotnet.runnable_projects()
  if #projects == 0 then
    vim.notify("No runnable projects found (need a .sln above the current file)", vim.log.levels.ERROR)
    return
  end

  if not dotnet.env_file() then
    vim.notify(
      "No PAIRTREE_* env file found — the web/API projects will throw "
        .. "ConfigurationException at startup.\nSet $PAIRTREE_ENV_FILE to a complete copy.",
      vim.log.levels.WARN
    )
  end

  vim.ui.select(projects, {
    prompt = "Debug which project?",
    format_item = function(p)
      return p.name .. (p.url and ("   " .. p.url) or "")
    end,
  }, function(choice)
    if not choice then
      return
    end
    -- Build just this project (and its references), like VS does on F5.
    dotnet.build(choice.csproj, { quiet = true }, function(ok, issues)
      if not ok then
        vim.notify(
          ("Build failed (%d issue(s)) — not launching. See quickfix."):format(issues),
          vim.log.levels.ERROR
        )
        return
      end
      if not vim.uv.fs_stat(choice.dll) then
        vim.notify("Built, but no DLL at " .. choice.dll, vim.log.levels.ERROR)
        return
      end
      vim.notify("Debugging " .. choice.name, vim.log.levels.INFO)
      dap.run(to_config(choice))
    end)
  end)
end

local function attach_to_process()
  ensure_dap().run(attach_config())
end

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "netcoredbg" } },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = {
      { "<leader>dn", pick_build_and_debug, desc = "Build & debug .NET project" },
      { "<leader>dA", attach_to_process, desc = "Attach to .NET process" },
    },
    -- NOTE: LazyVim's dap extra defines nvim-dap with `config = function()`,
    -- which ignores `opts` entirely -- an `opts` function here would silently
    -- never run. Hook lazy's own LazyLoad event instead so the <leader>dc path
    -- gets our configurations too. Avoids the LazyVim global, which is not
    -- guaranteed to exist this early.
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        desc = "Register netcoredbg adapter and .NET launch configs",
        callback = function(ev)
          if ev.data == "nvim-dap" then
            ensure_dap()
            return true
          end
        end,
      })
    end,
  },
}
