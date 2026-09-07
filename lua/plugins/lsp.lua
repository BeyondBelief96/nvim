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

          -- Apply auto-fixable lint problems on save, like VS Code's
          -- "source.fixAll" code action on save.
          --
          -- eslint's :LspEslintFixAll uses request_sync internally, so it is
          -- safe to run straight from BufWritePre.
          if client.name == "eslint" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = ev.buf,
              command = "LspEslintFixAll",
            })
          end

          -- oxlint's :LspOxlintFixAll uses client:exec_cmd, which is async and
          -- therefore races BufWritePre -- the file is written before the edits
          -- arrive, and the buffer is left modified afterwards. Issue the same
          -- workspace command synchronously instead so fixes land before save.
          --
          -- Note oxlint only applies fixes it classifies as safe (its default
          -- fixKind = "safe_fix"). Rules whose fix is "dangerous" -- eqeqeq and
          -- no-debugger among them -- are reported but never auto-applied.
          if client.name == "oxlint" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = ev.buf,
              callback = function()
                client:request_sync("workspace/executeCommand", {
                  command = "oxc.fixAll",
                  arguments = { { uri = vim.uri_from_bufnr(ev.buf) } },
                }, 2000, ev.buf)
              end,
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
        includeInlayVariableTypeHints = true,
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
      -- oxlint / eslint arbitration
      --
      -- oxlint's root markers are precise (.oxlintrc.json, oxlint.config.ts, or
      -- an "oxlint" mention in package.json) but it does not declare
      -- workspace_required, so with no match it starts anyway without a root.
      -- Fixed just below.
      --
      -- eslint has the opposite problem: it roots on a lockfile or .git, so it attaches
      -- to virtually any JS project -- including oxlint-only ones, where it
      -- starts a server with no config to work from and reports nothing useful.
      --
      -- So the rule is: skip eslint when the project has oxlint config and no
      -- eslint config. A project configured for both keeps both.
      -- ---------------------------------------------------------------------
      local OXLINT_MARKERS = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
      local ESLINT_MARKERS = {
        "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
        "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
        ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json",
        ".eslintrc.yaml", ".eslintrc.yml",
      }

      local function found_upward(bufnr, markers)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
          return false
        end
        return vim.fs.find(markers, { path = fname, upward = true })[1] ~= nil
      end

      -- package.json can also carry eslint config inline under "eslintConfig".
      local function package_json_has_eslint(bufnr)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
          return false
        end
        local pkg = vim.fs.find({ "package.json" }, { path = fname, upward = true })[1]
        if not pkg then
          return false
        end
        local ok, lines = pcall(vim.fn.readfile, pkg)
        if not ok then
          return false
        end
        local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
        return decoded_ok and type(decoded) == "table" and decoded.eslintConfig ~= nil
      end

      -- oxlint's shipped config has no `workspace_required`, so when its root
      -- markers match nothing it still calls on_dir(nil) and starts rootless,
      -- attaching to every JS/TS buffer. eslint sets workspace_required and so
      -- correctly stays out. Setting it here makes oxlint behave the same way:
      -- no oxlint project root, no oxlint server.
      vim.lsp.config("oxlint", { workspace_required = true })

      -- Captured before the override so the wrapper can delegate to it.
      local eslint_root_dir = vim.lsp.config.eslint.root_dir

      vim.lsp.config("eslint", {
        root_dir = function(bufnr, on_dir)
          if found_upward(bufnr, OXLINT_MARKERS)
            and not found_upward(bufnr, ESLINT_MARKERS)
            and not package_json_has_eslint(bufnr)
          then
            -- Returning without calling on_dir leaves eslint unstarted here.
            return
          end
          return eslint_root_dir(bufnr, on_dir)
        end,
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
          "oxlint",                   -- fast Rust linter; auto-used where a
                                      -- project has oxlint config (see above)
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
        -- oxfmt is installed as a *formatter* (conform runs its CLI -- see
        -- lua/plugins/formatting.lua), not as a language server. mason-lspconfig
        -- would otherwise auto-enable it just because the package is present,
        -- and like oxlint it declares no workspace_required, so it would attach
        -- to every JS/TS buffer even in projects with no oxfmt config.
        automatic_enable = { exclude = { "oxfmt" } },
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
