return {
  -- Auto-close brackets and quotes, with treesitter awareness so it doesn't
  -- fire inside strings or comments.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },

  -- Auto-close and auto-rename HTML/JSX tags. Type <div> and get </div>;
  -- edit one side of a pair and the other follows.
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte", "markdown" },
    opts = {},
  },

  -- Surround: cs"' changes "x" to 'x', ysiw" wraps a word in quotes,
  -- ds( removes surrounding parens.
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    version = "*",
    opts = {},
  },

  -- Show CSS/Tailwind colour values as actual colours in the buffer.
  {
    "brenoprata10/nvim-highlight-colors",
    ft = { "css", "scss", "less", "html", "javascriptreact", "typescriptreact", "lua" },
    opts = { render = "virtual", enable_tailwind = true },
  },

  -- Highlight and list TODO/FIXME/HACK comments.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
    keys = {
      { "<leader>pt", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },
}
