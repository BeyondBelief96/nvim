-- Treesitter parses your code into a real syntax tree. That gives accurate
-- highlighting, indentation, and structural text objects (select/move by
-- function, class, argument...).

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- pinned: `main` is a rewrite with a different API
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "c", "cpp", "cmake", "make",
        "javascript", "typescript", "tsx", "jsdoc",
        "html", "css", "scss",
        "json", "jsonc", "yaml", "toml",
        "lua", "luadoc", "vim", "vimdoc", "query",
        "bash", "markdown", "markdown_inline", "regex", "diff", "gitcommit",
      },
      auto_install = true, -- grab a parser on demand for unlisted filetypes
      highlight = { enable = true },
      indent = { enable = true },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",   -- start selecting at the cursor node
          node_incremental = "<C-space>", -- grow to the parent node
          node_decremental = "<BS>",      -- shrink back
          scope_incremental = false,
        },
      },

      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- jump forward to the next match if not inside one
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",["ia"] = "@parameter.inner",
            ["ai"] = "@conditional.outer", ["ii"] = "@conditional.inner",
            ["al"] = "@loop.outer",     ["il"] = "@loop.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
        },
        swap = {
          enable = true,
          swap_next = { ["<leader>a"] = "@parameter.inner" },
          swap_previous = { ["<leader>A"] = "@parameter.inner" },
        },
      },
    },
  },

  -- Keep the enclosing function/class header pinned to the top of the window.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = { max_lines = 3 },
  },
}
