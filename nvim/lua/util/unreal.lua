-- Unreal Engine helpers: project discovery, engine lookup, building, and
-- generating the clangd compile database.
--
-- Used by lua/config/autocmds.lua (:UnrealBuild, :UnrealCompileCommands).
-- clangd setup itself lives in lua/plugins/cpp.lua.
--
-- WINDOWS ONLY. UnrealBuildTool drives MSVC against C:\ paths, so these
-- commands are not registered on the WSL side of this shared config. Editing
-- Unreal source from WSL nvim works, but building and indexing do not.

local platform = require("util.platform")

local M = {}

--- Walk up from `from` looking for a .uproject.
--- Unlike solutions there is no nesting problem here, so the NEAREST one wins.
---@param from? string file or dir to start from
---@return string|nil uproject absolute path
function M.find_project(from)
  from = from or vim.api.nvim_buf_get_name(0)
  if from == "" then
    from = vim.fs.joinpath(vim.fn.getcwd(), "_")
  end
  for dir in vim.fs.parents(from) do
    local found = vim.fn.globpath(dir, "*.uproject", false, true)
    if #found > 0 then
      return found[1]
    end
  end
  return nil
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

--- The engine a .uproject is bound to, via its "EngineAssociation" field.
---
--- A launcher-installed engine associates by version ("5.6") and lives under
--- Program Files. A source build associates by GUID and is registered in
--- HKCU\Software\Epic Games\Unreal Engine\Builds; that case is not handled
--- here, so set g:unreal_engine_root manually if you ever use one.
---@param uproject string
---@return string|nil root engine directory
function M.engine_root(uproject)
  if vim.g.unreal_engine_root then
    return vim.g.unreal_engine_root
  end

  local content = read_file(uproject)
  local assoc = content and content:match('"EngineAssociation"%s*:%s*"([^"]*)"')
  if assoc and assoc:match("^%d+%.%d+$") then
    local root = platform.from_windows("C:/Program Files/Epic Games/UE_" .. assoc)
    if vim.uv.fs_stat(root) then
      return root
    end
  end

  -- Fall back to the newest installed engine.
  local installs = vim.fn.globpath(platform.from_windows("C:/Program Files/Epic Games"), "UE_*", false, true)
  table.sort(installs)
  return installs[#installs]
end

--- The editor target name Unreal generates for a project: "<Name>Editor".
---@param uproject string
---@return string
function M.editor_target(uproject)
  return vim.fn.fnamemodify(uproject, ":t:r") .. "Editor"
end

--- Does this project actually have C++ in it? A Blueprint-only project has no
--- Source/ directory, and UnrealBuildTool has nothing to describe or compile.
---@param uproject string
---@return boolean
function M.has_source(uproject)
  local src = vim.fs.joinpath(vim.fs.dirname(uproject), "Source")
  local stat = vim.uv.fs_stat(src)
  return stat ~= nil and stat.type == "directory"
end

--- Resolve the project and engine, reporting clearly if anything is missing.
---@return table|nil ctx { uproject, dir, engine, target, build_bat }
function M.context()
  if not platform.is_windows then
    vim.notify("Unreal commands are Windows-only (UnrealBuildTool needs MSVC)", vim.log.levels.ERROR)
    return nil
  end

  local uproject = M.find_project()
  if not uproject then
    vim.notify("No .uproject found above the current file", vim.log.levels.ERROR)
    return nil
  end

  if not M.has_source(uproject) then
    vim.notify(
      ("%s has no Source/ directory — it is Blueprint-only. Add a C++ class from the Unreal Editor first."):format(
        vim.fn.fnamemodify(uproject, ":t")
      ),
      vim.log.levels.ERROR
    )
    return nil
  end

  local engine = M.engine_root(uproject)
  if not engine then
    vim.notify("Could not locate an Unreal Engine install", vim.log.levels.ERROR)
    return nil
  end

  local build_bat = vim.fs.joinpath(engine, "Engine", "Build", "BatchFiles", "Build.bat")
  if not vim.uv.fs_stat(build_bat) then
    vim.notify("Build.bat not found at " .. build_bat, vim.log.levels.ERROR)
    return nil
  end

  return {
    uproject = uproject,
    dir = vim.fs.dirname(uproject),
    engine = engine,
    target = M.editor_target(uproject),
    build_bat = build_bat,
  }
end

--- MSVC diagnostics, as UnrealBuildTool relays them:
---   C:\path\File.cpp(12,5): error C2065: 'Foo': undeclared identifier
--- Older toolchains omit the column, so both shapes are matched.
--- %-G%.%# discards everything else so the quickfix list stays clean.
local function errorformat(include_warnings)
  local efm = [[%f(%l\,%c): error %m,%f(%l): error %m]]
  if include_warnings then
    efm = efm .. [[,%f(%l\,%c): warning %m,%f(%l): warning %m]]
  end
  return efm .. [[,%-G%.%#]]
end

--- Build.bat and the .uproject both live under paths containing spaces
--- ("Program Files", "Unreal Projects"). Invoking them through `cmd.exe /c`
--- is a quoting minefield: cmd strips outer quotes after /c and then splits
--- the batch path on its space, which hangs waiting on a bogus prompt rather
--- than failing cleanly. PowerShell's call operator takes each argument as a
--- discrete string, so it survives the spaces.
---@param exe string
---@param args string[]
---@return string[] argv
local function powershell(exe, args)
  local parts = { ('& "%s"'):format(exe) }
  for _, a in ipairs(args) do
    parts[#parts + 1] = ('"%s"'):format(a)
  end
  return { "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", table.concat(parts, " ") }
end

local function run(cmd, cwd, title, opts, cb)
  opts = opts or {}
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      local out = (res.stdout or "") .. "\n" .. (res.stderr or "")
      local items = vim.fn.getqflist({
        lines = vim.split(out, "\n"),
        efm = errorformat(opts.warnings),
      }).items

      -- UBT echoes each diagnostic once per module it appears in.
      local seen, uniq = {}, {}
      for _, it in ipairs(items) do
        local key = table.concat({ it.filename or it.bufnr or "", it.lnum, it.col, it.text }, "\0")
        if not seen[key] then
          seen[key] = true
          uniq[#uniq + 1] = it
        end
      end

      vim.fn.setqflist({}, " ", { title = title, items = uniq })

      local ok = res.code == 0
      if #uniq > 0 then
        vim.cmd("botright copen")
        vim.cmd("wincmd p")
        vim.notify(("%s: %d issue(s), :cn / :cp to step through"):format(title, #uniq), vim.log.levels.WARN)
      else
        vim.cmd("cclose")
      end

      if cb then
        cb(ok, #uniq, out)
      end
    end)
  end)
end

--- Build the editor target and put diagnostics in the quickfix list.
---@param opts? { warnings?: boolean, configuration?: string }
function M.build(opts)
  opts = opts or {}
  local ctx = M.context()
  if not ctx then
    return
  end

  local config = opts.configuration or "Development"
  vim.notify(("Building %s %s Win64…"):format(ctx.target, config), vim.log.levels.INFO)

  run(
    powershell(ctx.build_bat, {
      ctx.target,
      "Win64",
      config,
      "-project=" .. ctx.uproject,
      "-game",
      "-engine",
      "-progress",
    }),
    ctx.dir,
    "Unreal build " .. ctx.target,
    opts,
    function(ok, count)
      if ok and count == 0 then
        vim.notify("Build succeeded, 0 errors", vim.log.levels.INFO)
      elseif count == 0 then
        vim.notify("Build failed with no file-anchored errors, run Build.bat in a terminal", vim.log.levels.ERROR)
      end
    end
  )
end

--- Regenerate compile_commands.json via UnrealBuildTool, then restart clangd.
---
--- Rerun this whenever you add a module, add a .cpp/.h file, or change a
--- .Build.cs. clangd only knows about files the database mentions; a brand new
--- file gets no completion until the database is regenerated.
function M.compile_commands()
  local ctx = M.context()
  if not ctx then
    return
  end

  vim.notify("Generating compile_commands.json (this takes a minute)…", vim.log.levels.INFO)

  run(
    powershell(ctx.build_bat, {
      "-mode=GenerateClangDatabase",
      "-project=" .. ctx.uproject,
      "-game",
      "-engine",
      ctx.target,
      "Win64",
      "Development",
    }),
    ctx.dir,
    "Unreal compile database",
    { warnings = false },
    function(ok, _, out)
      if not ok then
        vim.notify("GenerateClangDatabase failed, see :copen or run it in a terminal", vim.log.levels.ERROR)
        return
      end

      -- UBT writes the database to the ENGINE root, not next to the .uproject,
      -- and reports the location on a "ClangDatabase written to <path>" line.
      -- That location is shared by every project on this machine, so mirror it
      -- into the project, which is where clangd roots (see lua/plugins/cpp.lua).
      local wanted = vim.fs.joinpath(ctx.dir, "compile_commands.json")
      local produced = out:match("written to ([%a]:[^\r\n]-compile_commands%.json)")
        or vim.fs.joinpath(ctx.engine, "compile_commands.json")

      if produced ~= wanted and vim.uv.fs_stat(produced) then
        local src = io.open(produced, "rb")
        local dst = src and io.open(wanted, "wb")
        if src and dst then
          dst:write(src:read("*a"))
          src:close()
          dst:close()
        elseif src then
          src:close()
        end
      end

      if vim.uv.fs_stat(wanted) then
        vim.notify("compile_commands.json ready, restarting clangd", vim.log.levels.INFO)
        -- :LspRestart is not always defined (it comes and goes between
        -- nvim-lspconfig versions), so fall back to stopping the client and
        -- reloading the buffer, which reattaches it against the new database.
        if not pcall(vim.cmd, "LspRestart clangd") then
          for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
            client:stop(true)
          end
          vim.defer_fn(function()
            vim.cmd("silent! edit")
          end, 300)
        end
      else
        vim.notify("UBT reported success but no compile_commands.json was found", vim.log.levels.ERROR)
      end
    end
  )
end

return M
