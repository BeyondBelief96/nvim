-- Autocomplete. blink.cmp is the fast modern completion engine; it ships
-- prebuilt binaries so no Rust toolchain is needed on a new machine.

return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "1.*", -- a tag, so the prebuilt binary is downloaded
    dependencies = {
      -- Snippet collection (React, C++, etc.) that blink reads from.
      { "rafamadriz/friendly-snippets" },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' keymap:
      --   <C-space>  open menu / open docs
      --   <C-n>/<C-p> or <Up>/<Down>  select
      --   <C-y>      accept
      --   <C-e>      hide
      --   <Tab>/<S-Tab>  jump between snippet placeholders
      keymap = {
        preset = "default",
        -- Enter accepts the selected item, like VS Code. Falls through to a
        -- normal newline when nothing is selected.
        ["<CR>"] = { "accept", "fallback" },
        -- Tab cycles the menu when it's open.
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      },

      appearance = { nerd_font_variant = "mono" },

      completion = {
        -- Show the documentation popup automatically after a short pause.
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        -- Ghost text preview of the selected item.
        ghost_text = { enabled = true },
        menu = {
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },
          },
        },
      },

      signature = { enabled = true },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
          -- lazydev supplies Neovim API completions; score it above plain LSP
          -- so `vim.` completions are useful when editing this config.
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },

      -- Rust fuzzy matcher, with a Lua fallback if the binary is unavailable.
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
