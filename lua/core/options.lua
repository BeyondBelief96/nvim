-- Editor settings. Everything here is built into Neovim -- no plugins involved.
local opt = vim.opt

-- Carried over from the old init.vim
opt.scrolloff = 12 -- keep 12 lines of context above/below the cursor
opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true -- tabs insert spaces
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true -- ...unless the pattern has a capital letter
opt.hlsearch = false
opt.incsearch = true

-- Files / undo
opt.swapfile = false
opt.backup = false
opt.undofile = true -- persistent undo across sessions
opt.undodir = vim.fn.stdpath("state") .. "/undo"

-- UI
opt.termguicolors = true -- 24-bit color, required by modern colorschemes
opt.signcolumn = "yes" -- always show it so text doesn't jump when diagnostics appear
opt.cursorline = true
opt.wrap = false
opt.splitright = true
opt.splitbelow = true
opt.showmode = false -- lualine already shows the mode

-- Responsiveness
opt.updatetime = 250 -- how long before CursorHold fires (diagnostics, git signs)
opt.timeoutlen = 400 -- how long to wait for a mapped key sequence (which-key popup)

-- Completion behaviour
opt.completeopt = { "menu", "menuone", "noselect" }

-- Show whitespace that usually matters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Live substitution preview in a split
opt.inccommand = "split"

-- Use the system clipboard. Scheduled so it doesn't slow down startup while
-- Neovim probes for a clipboard provider (notably slow under WSL).
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)
