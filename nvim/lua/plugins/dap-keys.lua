-- Visual Studio style function keys for the debugger.
--
-- Muscle memory from VS carries straight over, which matters because VS stays
-- the fallback for the occasional Unreal debugging session nvim cannot cover.
-- Verified free: nothing else in this config binds any F key, in any mode.
--
-- These sit alongside LazyVim's <leader>d mappings rather than replacing them.
-- Both work. The <leader>d set is the reliable one; the shifted F keys below
-- depend on the terminal actually distinguishing Shift+F, which not every
-- terminal does.

return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = {
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Debug: Start/Continue",
      },
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Debug: Toggle Breakpoint",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Debug: Step Over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Debug: Step Into",
      },

      -- Shift variants: VS uses these, but terminals often send an unrelated
      -- keycode for them. If they do nothing, use <leader>do and <leader>dt.
      {
        "<S-F11>",
        function()
          require("dap").step_out()
        end,
        desc = "Debug: Step Out",
      },
      {
        "<S-F5>",
        function()
          require("dap").terminate()
        end,
        desc = "Debug: Stop",
      },
    },
  },
}
