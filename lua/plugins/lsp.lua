-- Language servers: diagnostics, type checking, go-to-definition, rename,
-- hover docs, code actions. This is the bulk of the "VS Code feel".
--
-- Neovim 0.11+ has a built-in LSP config system (`vim.lsp.config` /
-- `vim.lsp.enable`). nvim-lspconfig now mostly just ships the per-server
-- defaults for it, and mason installs the server binaries.

return {
  -- Lua LSP that understands the Neovim API, for editing this config itself.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Little spinner in the corner while a server indexes.
  { "j-hui/fidget.nvim", opts = { notification = { window = { winblend = 0 } } } },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- ---------------------------------------------------------------------
      -- Diagnostics display
      -- ---------------------------------------------------------------------
      vim.diagnostic.config({
        virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
        underline = true,
        update_in_insert = false, -- don't nag mid-keystroke
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
      })

      -- ---------------------------------------------------------------------
      -- Keymaps -- bound per-buffer, only once a server actually attaches
      -- ---------------------------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("cfg_lsp_attach", { clear = true }),
        callback = function(ev)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end

          local tb = require("telescope.builtin")
          map("gd", tb.lsp_definitions, "Go to definition")
          map("gr", tb.lsp_references, "Go to references")
          map("gI", tb.lsp_implementations, "Go to implementation")
          map("gy", tb.lsp_type_definitions, "Go to type definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("<leader>ls", tb.lsp_document_symbols, "Document symbols")
          map("<leader>lS", tb.lsp_dynamic_workspace_symbols, "Workspace symbols")

          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<C-s>", vim.lsp.buf.signature_help, "Signature help", "i")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end

          -- Inlay hints (parameter names, inferred types), toggleable.
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
            end, "Toggle inlay hints")
          end

          -- Highlight other references to the symbol under the cursor.
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup("cfg_lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = ev.buf,
              group = hl_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = ev.buf,
              group = hl_group,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- ESLint: apply all auto-fixable problems on save, like VS Code's
          -- "source.fixAll.eslint" code action on save.
          if client.name == "eslint" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = ev.buf,
              command = "LspEslintFixAll",
            })
          end
        end,
      })

      -- ---------------------------------------------------------------------
      -- Capabilities -- tell servers what this client can do.
      -- blink.cmp advertises richer completion support than the default.
      -- The '*' config applies to every server.
      -- ---------------------------------------------------------------------
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
      })

      -- ---------------------------------------------------------------------
      -- Per-server settings. Anything not listed here just uses the
      -- nvim-lspconfig default.
      -- ---------------------------------------------------------------------
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      -- TypeScript / JavaScript. Inlay hints are off by default in tsserver;
      -- these turn on the same set VS Code shows.
      local ts_inlay = {
        includeInlayParameterNameHints = "literal",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = false,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
      vim.lsp.config("ts_ls", {
        settings = {
          typescript = { inlayHints = ts_inlay },
          javascript = { inlayHints = ts_inlay },
        },
      })

      -- C / C++. The flags matter:
      --   background-index      -- index the whole project, not just open files
      --   clang-tidy            -- static analysis diagnostics inline
      --   header-insertion      -- don't auto-add #includes unprompted
      --   compile-commands-dir  -- where to find compile_commands.json
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
          "--offset-encoding=utf-16",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = { validate = { enable = true } },
        },
      })

      -- ---------------------------------------------------------------------
      -- Install and enable. mason-lspconfig calls vim.lsp.enable() for every
      -- server it manages, so nothing else is needed to turn them on.
      -- ---------------------------------------------------------------------
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Web
          "ts_ls",                    -- TypeScript/JavaScript type checking
          "eslint",                   -- JS/TS linting (+ fix on save)
          "html",
          "cssls",
          "emmet_language_server",    -- HTML/CSS abbreviation expansion
          "tailwindcss",
          "jsonls",
          "yamlls",
          -- C/C++ and build
          "clangd",
          "neocmake",                 -- CMakeLists.txt language server
          -- Config
          "lua_ls",
        },
        automatic_enable = true,
      })

      -- Non-LSP tooling: formatters and debug adapters.
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettierd",          -- fast Prettier daemon (JS/TS/HTML/CSS/JSON/MD)
          "clang-format",       -- C/C++ formatting
          "stylua",             -- Lua formatting
          "codelldb",           -- C/C++ debugger adapter
          "js-debug-adapter",   -- Node/browser debugger adapter
        },
        run_on_start = true,
        auto_update = false,
      })
    end,
  },

  -- Project-wide diagnostics list -- the equivalent of VS Code's Problems panel.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = { focus = true },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (project)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbol outline" },
      { "<leader>xl", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    },
  },
}
