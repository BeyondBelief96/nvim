-- ~/.config/nvim/init.lua
-- Entry point. Order matters: leader must be set before lazy.nvim loads,
-- otherwise plugin keymaps get bound to the wrong prefix.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.lazy") -- bootstraps lazy.nvim, then loads everything in lua/plugins/
