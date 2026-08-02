-- telescope-fzf-native is a compiled C sorter. It has to be built, and the
-- build differs by platform: a plain `make` on Linux, cmake on Windows (which
-- has no make). If the build has not happened, load_extension throws and takes
-- the whole telescope config down with it, so it is guarded -- telescope then
-- falls back to its pure-Lua sorter, which is slower but perfectly usable.
local platform = require("util.platform")

local windows_build = table.concat({
  "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release",
  "cmake --build build --config Release",
  "cmake --install build --prefix build",
}, " && ")

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = platform.is_windows and windows_build or "make",
    },
  },
  opts = function(_, opts)
    pcall(function()
      require("telescope").load_extension("fzf")
    end)
  end,
}
