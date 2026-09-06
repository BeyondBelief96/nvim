-- Fuzzy finding: files, live grep, symbols, git. Replaces the fzf.vim setup
-- from the old config, with the same keys bound to the equivalent pickers.

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Native C sorter -- much faster on big repos. Needs make + gcc, which
      -- bootstrap.sh installs. If the build fails Telescope still works, just
      -- with the slower Lua sorter.
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = {
      -- Carried over from the old init.vim
      { "<C-p>", "<cmd>Telescope git_files<cr>", desc = "Find git files" },
      { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find files" },

      -- Additions
      { "<leader>ps", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
      { "<leader>pw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
      { "<leader>pb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>ph", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>pk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>pr", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
      { "<leader>pd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>po", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in buffer" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          path_display = { "truncate" },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close, -- close from insert mode directly
            },
          },
          file_ignore_patterns = {
            "%.git/", "node_modules/", "build/", "%.o$", "%.a$", "%.so$",
          },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })

      pcall(telescope.load_extension, "fzf")
      telescope.load_extension("ui-select") -- route vim.ui.select through Telescope
    end,
  },
}
