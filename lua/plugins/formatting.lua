-- Format on save, VS Code style. conform.nvim picks a formatter per filetype
-- and falls back to the LSP's own formatter when none is configured.

-- Projects that opt into oxfmt (oxc's Prettier-compatible formatter) get it
-- instead of Prettier. Everything else keeps Prettier, so this is opt-in per
-- project and nothing changes for repos that have never heard of oxc.
local OXFMT_MARKERS = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }

local function uses_oxfmt(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == "" then
    return false
  end
  return vim.fs.find(OXFMT_MARKERS, { path = fname, upward = true })[1] ~= nil
end

-- conform accepts a function per filetype, called with the buffer, returning
-- the formatter list to use for it. Detection walks upward from the file, so
-- a monorepo can mix oxfmt and Prettier across packages.
local function web(bufnr)
  if uses_oxfmt(bufnr) then
    return { "oxfmt" }
  end
  return { "prettierd", "prettier", stop_after_first = true }
end

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
      {
        "<leader>tf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save",
      },
    },
    opts = {
      -- oxfmt where the project configures it, Prettier otherwise.
      formatters_by_ft = {
        javascript = web,
        javascriptreact = web,
        typescript = web,
        typescriptreact = web,
        html = web,
        css = web,
        scss = web,
        json = web,
        jsonc = web,
        yaml = web,
        markdown = web,

        c = { "clang_format" },
        cpp = { "clang_format" },

        lua = { "stylua" },
      },

      formatters = {
        -- Belt and braces: even if oxfmt were somehow selected without a
        -- config root, require_cwd stops it running rather than letting it
        -- reformat a Prettier project with oxc defaults.
        oxfmt = { require_cwd = true },
      },

      format_on_save = function(bufnr)
        -- <leader>tf flips this off when you need to save without reformatting.
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,
    },
    init = function()
      -- Make :w-triggered formatting available to `gq` too.
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
