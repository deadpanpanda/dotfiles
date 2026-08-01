-- Shared .NET helpers: solution discovery, runnable-project discovery, building.
-- Used by lua/config/autocmds.lua (build -> quickfix) and
-- lua/plugins/dotnet-debug.lua (launch/attach under netcoredbg).

local M = {}

--- Walk up to the OUTERMOST .sln so a nested single-project solution
--- (src/Pairtree.Control/Pairtree.Control.sln) never wins over the real one
--- (src/PairtreeV2.sln). Stops climbing at the repo root.
---@param from? string file or dir to start from
---@return string|nil sln absolute path to the solution file
function M.find_solution(from)
  from = from or vim.api.nvim_buf_get_name(0)
  if from == "" then
    from = vim.fs.joinpath(vim.fn.getcwd(), "_")
  end
  local outermost = nil
  for dir in vim.fs.parents(from) do
    local found = vim.fn.globpath(dir, "*.sln", false, true)
    vim.list_extend(found, vim.fn.globpath(dir, "*.slnx", false, true))
    if #found > 0 then
      outermost = found[1]
    end
    if vim.uv.fs_stat(vim.fs.joinpath(dir, ".git")) then
      break
    end
  end
  return outermost
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  return content
end

--- Read the "Project" launch profile out of Properties/launchSettings.json.
--- Profiles with commandName "IISExpress" are Windows-only and ignored.
local function launch_profile(proj_dir)
  local path = vim.fs.joinpath(proj_dir, "Properties", "launchSettings.json")
  local content = read_file(path)
  if not content then
    return nil
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" or type(data.profiles) ~= "table" then
    return nil
  end
  for name, p in pairs(data.profiles) do
    if p.commandName == "Project" then
      return { name = name, url = p.applicationUrl, env = p.environmentVariables }
    end
  end
  return nil
end

--- Every project in the solution directory that produces a runnable process:
--- Web/Worker SDK projects, plus classlib-SDK projects with <OutputType>Exe.
---@param sln? string path to the solution (defaults to M.find_solution())
---@return table[] projects sorted by name
function M.runnable_projects(sln)
  sln = sln or M.find_solution()
  if not sln then
    return {}
  end
  local root = vim.fs.dirname(sln)
  local projects = {}

  for _, csproj in ipairs(vim.fn.globpath(root, "*/*.csproj", false, true)) do
    local content = read_file(csproj)
    if content then
      local sdk = content:match('Sdk="([^"]+)"') or ""
      local is_runnable = sdk:match("Web$") ~= nil
        or sdk:match("Worker$") ~= nil
        or content:match("<OutputType>%s*Exe%s*</OutputType>") ~= nil
      if is_runnable then
        local dir = vim.fs.dirname(csproj)
        local tfm = content:match("<TargetFramework>([^<]+)</TargetFramework>")
        -- AssemblyName wins if set, else the .csproj filename. These differ in
        -- this repo: Pairtree.FeedProvider/ builds Pairtree.Feeds.Provider.dll
        local asm = content:match("<AssemblyName>([^<]+)</AssemblyName>")
          or vim.fn.fnamemodify(csproj, ":t:r")
        if tfm then
          local profile = launch_profile(dir)
          projects[#projects + 1] = {
            name = vim.fn.fnamemodify(csproj, ":t:r"),
            csproj = csproj,
            dir = dir,
            tfm = tfm,
            dll = vim.fs.joinpath(dir, "bin", "Debug", tfm, asm .. ".dll"),
            url = profile and profile.url or nil,
            env = profile and profile.env or nil,
          }
        end
      end
    end
  end

  table.sort(projects, function(a, b)
    return a.name < b.name
  end)
  return projects
end

--- Locate the PAIRTREE_* environment file, in precedence order:
---   1. $PAIRTREE_ENV_FILE  (set this to your own complete/private copy)
---   2. /etc/pairtree.conf  (what systemd uses via EnvironmentFile= in prod)
---   3. <repo>/config/dev/*/etc/pairtree.conf (committed dev baseline)
---
--- NOTE: the C# code reads these as ordinary environment variables. Creating
--- /etc/pairtree.conf does NOT by itself help a locally launched process --
--- only systemd reads that file. So we inject the values into the debuggee's
--- environment, which is the same thing config/windows env/pairtree_env.bat
--- does with `setx` for the Visual Studio devs.
---@param sln? string
---@return string|nil path
function M.env_file(sln)
  local explicit = vim.env.PAIRTREE_ENV_FILE
  if explicit and explicit ~= "" and vim.uv.fs_stat(explicit) then
    return explicit
  end
  if vim.uv.fs_stat("/etc/pairtree.conf") then
    return "/etc/pairtree.conf"
  end
  sln = sln or M.find_solution()
  if sln then
    local repo = vim.fs.dirname(vim.fs.dirname(sln)) -- src/ -> repo root
    local found = vim.fn.globpath(vim.fs.joinpath(repo, "config", "dev"), "*/etc/pairtree.conf", false, true)
    if #found > 0 then
      return found[1]
    end
  end
  return nil
end

--- Parse a KEY=VALUE env file. Values are taken as the rest of the line, so
--- connection strings containing spaces and semicolons survive intact --
--- naive shell sourcing mangles PAIRTREE_DB_CONN ("...;User Id=...").
---@param path string
---@return table<string,string>
function M.load_env(path)
  local env = {}
  local content = read_file(path)
  if not content then
    return env
  end
  for line in content:gmatch("[^\r\n]+") do
    local trimmed = vim.trim(line)
    if trimmed ~= "" and not trimmed:match("^#") then
      local key, value = trimmed:match("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
      if key then
        env[key] = (vim.trim(value):gsub('^"(.*)"$', "%1"))
      end
    end
  end
  return env
end

--- MSBuild diagnostics look like:
---   /path/File.cs(5,16): error CS0161: message [/path/Proj.csproj]
--- %-G%.%# discards every other line so the quickfix list stays clean.
local function errorformat(include_warnings)
  return include_warnings and [[%f(%l\,%c): error %m,%f(%l\,%c): warning %m,%-G%.%#]]
    or [[%f(%l\,%c): error %m,%-G%.%#]]
end

--- Build `target` (a .sln or .csproj) and put diagnostics in the quickfix list.
---@param target string
---@param opts? { warnings?: boolean, quiet?: boolean }
---@param cb? fun(ok: boolean, count: integer)
function M.build(target, opts, cb)
  opts = opts or {}
  if not opts.quiet then
    vim.notify("Building " .. vim.fn.fnamemodify(target, ":t") .. "…", vim.log.levels.INFO)
  end

  vim.system({ "dotnet", "build", target, "-v", "q", "--nologo" }, { text = true }, function(res)
    vim.schedule(function()
      local out = (res.stdout or "") .. "\n" .. (res.stderr or "")
      local items = vim.fn.getqflist({
        lines = vim.split(out, "\n"),
        efm = errorformat(opts.warnings),
      }).items

      -- MSBuild's parallel loggers report each diagnostic more than once.
      local seen, uniq = {}, {}
      for _, it in ipairs(items) do
        local key = table.concat({ it.filename or it.bufnr or "", it.lnum, it.col, it.text }, "\0")
        if not seen[key] then
          seen[key] = true
          uniq[#uniq + 1] = it
        end
      end

      vim.fn.setqflist({}, " ", {
        title = "dotnet build " .. vim.fn.fnamemodify(target, ":t"),
        items = uniq,
      })

      local ok = res.code == 0
      if #uniq > 0 then
        vim.cmd("botright copen")
        vim.cmd("wincmd p")
        vim.notify(("Build: %d issue(s) — :cn / :cp to step through"):format(#uniq), vim.log.levels.WARN)
      else
        vim.cmd("cclose")
        if not opts.quiet then
          if ok then
            vim.notify("Build succeeded — 0 errors", vim.log.levels.INFO)
          else
            vim.notify(
              ("Build failed (exit %d) with no file-anchored errors — run `dotnet build` in a terminal"):format(
                res.code
              ),
              vim.log.levels.ERROR
            )
          end
        end
      end

      if cb then
        cb(ok and #uniq == 0, #uniq)
      end
    end)
  end)
end

return M
