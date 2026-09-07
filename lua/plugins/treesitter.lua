-- Treesitter parses your code into a real syntax tree. That gives accurate
-- highlighting, indentation, and structural text objects (select/move by
-- function, class, argument...).

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- pinned: `main` is a rewrite with a different API

    -- Neovim 0.12 dropped the `all` option from vim.treesitter.query's
    -- add_predicate/add_directive: handlers now ALWAYS receive
    -- `table<integer, TSNode[]>`. The master branch above still registers all
    -- six of its handlers with `all = false` and indexes `match[id]` expecting
    -- a single node (lua/nvim-treesitter/query_predicates.lua:19). It now gets
    -- a one-element list instead, which sails past the `if not node` guards and
    -- blows up on first use -- e.g. `#set-lang-from-info-string!` on any ```lang
    -- fence, giving "attempt to call method 'range' (a nil value)".
    --
    -- Restore the unwrapping that 0.11 did (neovim v0.11.0
    -- runtime/lua/vim/treesitter/query.lua:796,839 -- note it takes v[#v], the
    -- LAST node, not the first). We only unwrap when `all = false` is passed
    -- EXPLICITLY: that flag means "written against the old single-node API".
    -- 0.11 also unwrapped directives that passed no opts at all, but copying
    -- that would break 0.12-native plugins, which correctly expect lists.
    --
    -- Delete this whole block when the master pin above goes away.
    init = function()
      if vim.fn.has("nvim-0.12") == 0 then
        return
      end
      local query = require("vim.treesitter.query")
      if query._nvim012_all_shim then
        return
      end
      query._nvim012_all_shim = true

      local function unwrap_last(handler)
        return function(match, ...)
          local single = {}
          for id, nodes in pairs(match) do
            single[id] = nodes[#nodes]
          end
          return handler(single, ...)
        end
      end

      for _, name in ipairs({ "add_predicate", "add_directive" }) do
        local orig = query[name]
        query[name] = function(pred_name, handler, opts)
          if type(opts) == "table" and opts.all == false then
            handler = unwrap_last(handler)
          end
          return orig(pred_name, handler, opts)
        end
      end
    end,
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
