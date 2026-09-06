-- All non-plugin keymaps. Plugin-specific maps live next to their plugin spec
-- in lua/plugins/ so you can find them by feature.
--
-- <leader> is Space (set in init.lua).
local map = vim.keymap.set

-- ---------------------------------------------------------------------------
-- Carried over from the old init.vim
-- ---------------------------------------------------------------------------

-- <leader>pv used to be :Vex (netrw). It now toggles the nvim-tree sidebar --
-- see lua/plugins/ui.lua. :Vex still works if you want the old behaviour.

-- Reload config. The old `:so init.vim` no longer applies with a multi-file
-- Lua config, so this restarts Neovim's config the safe way: re-source
-- init.lua after clearing the module cache.
map("n", "<leader><CR>", function()
  for name, _ in pairs(package.loaded) do
    if name:match("^core") or name:match("^plugins") then
      package.loaded[name] = nil
    end
  end
  dofile(vim.env.MYVIMRC)
  vim.notify("Config reloaded", vim.log.levels.INFO)
end, { desc = "Reload config" })

-- <leader>w as a window-command prefix, e.g. <leader>wv, <leader>ws, <leader>wq
map("n", "<leader>w", "<C-w>", { desc = "+window", remap = true })

-- Quickfix navigation
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })

-- ---------------------------------------------------------------------------
-- Additions
-- ---------------------------------------------------------------------------

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Keep the cursor centred when jumping around
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move selected lines up/down, re-indenting as they go
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode when indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Paste over a selection without clobbering the unnamed register
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking selection" })

-- Delete without yanking
-- <leader>d is the debug prefix, so delete-without-yank lives on <leader>D.
map({ "n", "v" }, "<leader>D", [["_d]], { desc = "Delete without yanking" })

-- Window navigation without the <C-w> prefix
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Resize windows with arrows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Terminal: Esc leaves terminal-insert mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Diagnostics (the "Problems" equivalent). Buffer-local LSP maps are in
-- lua/plugins/lsp.lua and only bind once a server attaches.
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic under cursor" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })
