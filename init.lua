-- ~/.config/nvim/init.lua
-- Entry point. Order matters: leader must be set before lazy.nvim loads,
-- otherwise plugin keymaps get bound to the wrong prefix.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.keymaps")

-- The `vscode-neovim` extension runs this same config inside VS Code and sets
-- `vim.g.vscode`. In that case options and keymaps above still apply -- your
-- motions and editing habits come with you -- but everything in lua/plugins/
-- is skipped, because VS Code already provides LSP, completion, fuzzy find,
-- file tree, git gutter, terminal and debugging. lua/core/vscode.lua then
-- re-points the Neovim-UI keymaps at the equivalent VS Code commands.
--
-- See vscode/README.md for setup.
if vim.g.vscode then
  require("core.vscode")
  return
end

require("core.autocmds")
require("core.lazy") -- bootstraps lazy.nvim, then loads everything in lua/plugins/
