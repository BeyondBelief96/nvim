-- C++ and CMake. The rough equivalent of VS Code's C/C++ + CMake Tools
-- extensions: configure, build, run and debug targets without leaving Neovim.
--
-- clangd needs a compile_commands.json to know your include paths and flags.
-- cmake-tools generates one automatically (see cmake_build_options below);
-- for non-CMake projects use `bear -- make` or a compile_flags.txt.

local platform = require("core.platform")

-- Where CMake writes its build tree, and how clangd is pointed at the
-- compile_commands.json inside it.
--
-- Everywhere else: a per-build-type directory, symlinked into the project root
-- so clangd finds it. On native Windows, creating that symlink needs
-- Developer Mode or an elevated Neovim, so instead build into a plain `build/`
-- -- a directory clangd already searches on its own -- and skip the link.
-- The cost is that Debug and Release share one build tree there.
local build_directory = platform.is_windows and "build" or "build/${variant:buildType}"

return {
  -- Inlay hints, type hierarchy, and :ClangdSwitchSourceHeader.
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp", "objc", "objcpp" },
    opts = {
      inlay_hints = { inline = false },
      ast = {
        role_icons = {
          type = "", declaration = "", expression = "",
          specifier = "", statement = "", ["template argument"] = "",
        },
      },
    },
    keys = {
      { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch source/header" },
      { "<leader>ct", "<cmd>ClangdTypeHierarchy<cr>", desc = "Type hierarchy" },
      { "<leader>cs", "<cmd>ClangdSymbolInfo<cr>", desc = "Symbol info" },
    },
  },

  -- CMake driver: pick a build type and target, build, run, debug.
  {
    "Civitasv/cmake-tools.nvim",
    ft = { "c", "cpp", "cmake" },
    cmd = {
      "CMakeGenerate", "CMakeBuild", "CMakeRun", "CMakeDebug",
      "CMakeSelectBuildType", "CMakeSelectBuildTarget", "CMakeSelectLaunchTarget",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>mg", "<cmd>CMakeGenerate<cr>", desc = "CMake generate" },
      { "<leader>mb", "<cmd>CMakeBuild<cr>", desc = "CMake build" },
      { "<leader>mr", "<cmd>CMakeRun<cr>", desc = "CMake run" },
      { "<leader>md", "<cmd>CMakeDebug<cr>", desc = "CMake debug" },
      { "<leader>mt", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake select build type" },
      { "<leader>ms", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake select target" },
      { "<leader>mc", "<cmd>CMakeClean<cr>", desc = "CMake clean" },
      { "<leader>mk", "<cmd>CMakeStopExecutor<cr>", desc = "CMake stop" },
    },
    opts = {
      cmake_command = "cmake",
      cmake_build_directory = build_directory,
      cmake_generate_options = {
        "-D", "CMAKE_EXPORT_COMPILE_COMMANDS=1", -- this is what feeds clangd
        "-G", "Ninja",
      },
      -- Symlink compile_commands.json into the project root (see above).
      cmake_soft_link_compile_commands = not platform.is_windows,
      cmake_dap_configuration = {
        name = "cpp",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
        console = "integratedTerminal",
      },
      cmake_executor = { name = "quickfix", opts = { show = "always" } },
      cmake_runner = { name = "terminal" },
    },
  },
}
