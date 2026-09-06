return {
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- File explorer sidebar. <leader>pv used to open netrw (:Vex); it now opens
  -- this instead. Inside the tree: `a` add, `d` delete, `r` rename, `x` cut,
  -- `p` paste, `?` help.
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle" },
    keys = {
      { "<leader>pv", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
      { "<leader>pV", "<cmd>NvimTreeFindFileToggle<cr>", desc = "Reveal current file in explorer" },
    },
    opts = {
      view = { width = 34 },
      renderer = { group_empty = true },
      filters = { dotfiles = false, custom = { "^%.git$", "node_modules" } },
      git = { enable = true },
      diagnostics = { enable = true }, -- show LSP errors on files in the tree
      actions = { open_file = { quit_on_open = false } },
    },
    init = function()
      -- nvim-tree wants netrw disabled to avoid both claiming directory buffers.
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
  },

  -- Statusline.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "gruvbox-material",
        globalstatus = true, -- one statusline for all splits
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          -- Show the current CMake build type/target when in a CMake project.
          {
            function()
              local ok, cmake = pcall(require, "cmake-tools")
              if not ok then return "" end
              local t = cmake.get_build_target()
              return t and (" " .. t) or ""
            end,
            cond = function()
              return vim.bo.filetype == "cpp" or vim.bo.filetype == "c" or vim.bo.filetype == "cmake"
            end,
          },
          "encoding", "fileformat", "filetype",
        },
      },
    },
  },

  -- Popup showing what keys are available after a prefix. Genuinely the
  -- fastest way to learn a config -- press <leader> and wait.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>p", group = "find/project" },
        { "<leader>g", group = "git" },
        { "<leader>d", group = "debug" },
        { "<leader>m", group = "cmake" },
        { "<leader>c", group = "clangd/code" },
        { "<leader>l", group = "lsp symbols" },
        { "<leader>x", group = "diagnostics (trouble)" },
        { "<leader>t", group = "toggle" },
        { "<leader>b", group = "buffer" },
        { "<leader>w", group = "window", proxy = "<c-w>" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },

  -- Indentation guides.
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPost",
    opts = { indent = { char = "│" }, scope = { enabled = false } },
  },

  -- Integrated terminal. <C-\> toggles a floating shell; <leader>tg opens
  -- lazygit if you have it installed.
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { [[<C-\>]], desc = "Toggle terminal" },
      { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (split)" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = { border = "rounded" },
      shade_terminals = true,
    },
  },
}
