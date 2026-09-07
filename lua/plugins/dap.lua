-- Debugging. Breakpoints, stepping, variable inspection -- the F5/F10/F11
-- keys are deliberately the same as VS Code's.
--
-- Adapters (codelldb for C/C++, js-debug-adapter for Node) are installed by
-- mason-tool-installer in lua/plugins/lsp.lua.

-- Resolve a mason-installed adapter to something nvim-dap can actually spawn.
--
-- mason puts its shims in stdpath("data")/mason/bin, which is on Neovim's
-- $PATH, so the bare name is enough on Linux and macOS. On Windows some of
-- those shims are `.cmd` batch files (the npm-packaged adapters especially),
-- and CreateProcess -- which is what libuv, and so nvim-dap, ends up calling
-- -- cannot execute a batch file directly. `exepath()` applies %PATHEXT% and
-- gives the real filename; anything that turns out to be a script gets routed
-- through cmd.exe.
local function adapter_command(name)
  local path = vim.fn.exepath(name)
  if path == "" then
    -- Not installed yet. Hand back the bare name so nvim-dap reports the
    -- missing adapter itself rather than us guessing at a path.
    return name, {}
  end
  if path:lower():match("%.cmd$") or path:lower():match("%.bat$") then
    return "cmd.exe", { "/c", path }
  end
  return path, {}
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text", -- inline variable values while stepping
    },
    keys = {
      -- VS Code parity
      { "<F5>", function() require("dap").continue() end, desc = "Debug: start/continue" },
      { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: stop" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: step out" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },

      -- Leader equivalents
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
            if cond then require("dap").set_breakpoint(cond) end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end, mode = { "n", "v" }, desc = "Hover value" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({})

      -- Open the debug UI automatically when a session starts, close it after.
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticSignWarn", linehl = "Visual" })

      -- ---------------------------------------------------------------------
      -- C / C++  (codelldb). mason puts its binaries on Neovim's PATH.
      -- ---------------------------------------------------------------------
      local codelldb, codelldb_args = adapter_command("codelldb")
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb,
          args = vim.list_extend(codelldb_args, { "--port", "${port}" }),
        },
      }

      local cpp_config = {
        {
          name = "Launch executable",
          type = "codelldb",
          request = "launch",
          program = function()
            -- Default to the build dir cmake-tools uses.
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          terminal = "integrated",
        },
        {
          name = "Attach to process",
          type = "codelldb",
          request = "attach",
          pid = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }
      dap.configurations.cpp = cpp_config
      dap.configurations.c = cpp_config

      -- ---------------------------------------------------------------------
      -- JavaScript / TypeScript  (js-debug-adapter)
      -- ---------------------------------------------------------------------
      local js_debug, js_debug_args = adapter_command("js-debug-adapter")
      for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = js_debug,
            -- Fresh copy per adapter: list_extend mutates its first argument.
            args = vim.list_extend(vim.deepcopy(js_debug_args), { "${port}" }),
          },
        }
      end

      local js_config = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch current file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to process",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome against localhost:3000",
          url = "http://localhost:3000",
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
      for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[ft] = js_config
      end

      -- .vscode/launch.json is picked up automatically by nvim-dap on demand,
      -- so an explicit load_launchjs() call is no longer needed (and is
      -- deprecated). Configurations from it appear alongside the ones above.
    end,
  },
}
