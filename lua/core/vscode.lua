-- Loaded ONLY when this config runs inside VS Code via the `vscode-neovim`
-- extension (which sets `vim.g.vscode`). See init.lua for the branch, and
-- vscode/README.md for setup instructions.
--
-- The idea: lua/core/options.lua and lua/core/keymaps.lua load in both
-- environments, so motions and editing behaviour follow you into VS Code.
-- Everything in lua/plugins/ is skipped -- VS Code already provides LSP,
-- completion, file tree, fuzzy finder, git gutter, terminal and debugging,
-- and running two of each fights rather than helps.
--
-- This file then re-points the handful of keymaps that referred to Neovim UI
-- at the equivalent VS Code command.

local vscode = require("vscode")
local map = vim.keymap.set

-- Run a VS Code command by id. `vscode.action` is fire-and-forget, which is
-- what you want for keymaps -- `vscode.call` blocks for a return value.
local function action(name)
  return function()
    vscode.action(name)
  end
end

-- ---------------------------------------------------------------------------
-- Undo the terminal-only maps from keymaps.lua
-- ---------------------------------------------------------------------------

-- <leader><CR> reloaded the Lua config. Meaningless here -- the extension owns
-- the Neovim lifecycle. Point it at VS Code's own reload instead.
map("n", "<leader><CR>", action("workbench.action.reloadWindow"), { desc = "Reload VS Code window" })

-- <C-j>/<C-k> were quickfix navigation. Give them back to VS Code: <C-k> is
-- the prefix for a large family of default chords (<C-k> <C-s>, <C-k> z, ...)
-- and losing it makes VS Code feel broken. Diagnostics navigation already
-- lives on [d / ]d below.
pcall(vim.keymap.del, "n", "<C-j>")
pcall(vim.keymap.del, "n", "<C-k>")

-- The terminal-mode escape maps have no meaning: VS Code's terminal is not a
-- Neovim buffer.
pcall(vim.keymap.del, "t", "<Esc><Esc>")

-- ---------------------------------------------------------------------------
-- Windows -> VS Code editor groups
--
-- <leader>w was a proxy for <C-w>. VS Code owns <C-w> (close editor), so bind
-- the three splits you actually use rather than forwarding the whole prefix.
-- ---------------------------------------------------------------------------
pcall(vim.keymap.del, "n", "<leader>w")
map("n", "<leader>wv", action("workbench.action.splitEditorRight"), { desc = "Split right" })
map("n", "<leader>ws", action("workbench.action.splitEditorDown"), { desc = "Split down" })
map("n", "<leader>wq", action("workbench.action.closeActiveEditor"), { desc = "Close editor" })
map("n", "<leader>wo", action("workbench.action.closeOtherEditors"), { desc = "Close other editors" })

map("n", "<C-h>", action("workbench.action.navigateLeft"), { desc = "Group left" })
map("n", "<C-l>", action("workbench.action.navigateRight"), { desc = "Group right" })

map("n", "<C-Up>", action("workbench.action.increaseViewHeight"), { desc = "Increase height" })
map("n", "<C-Down>", action("workbench.action.decreaseViewHeight"), { desc = "Decrease height" })
map("n", "<C-Left>", action("workbench.action.decreaseViewWidth"), { desc = "Decrease width" })
map("n", "<C-Right>", action("workbench.action.increaseViewWidth"), { desc = "Increase width" })

-- ---------------------------------------------------------------------------
-- Buffers -> editor tabs
-- ---------------------------------------------------------------------------
map("n", "<S-h>", action("workbench.action.previousEditor"), { desc = "Previous editor" })
map("n", "<S-l>", action("workbench.action.nextEditor"), { desc = "Next editor" })
map("n", "<leader>bd", action("workbench.action.closeActiveEditor"), { desc = "Close editor" })

-- ---------------------------------------------------------------------------
-- Find (<leader>p) -- Telescope's slot, now VS Code's pickers
--
-- Note <C-p> is deliberately NOT mapped here: it stays VS Code's Quick Open,
-- which is the same thing the terminal config binds it to.
-- ---------------------------------------------------------------------------
map("n", "<leader>pf", action("workbench.action.quickOpen"), { desc = "Find files" })
map("n", "<leader>ps", action("workbench.action.findInFiles"), { desc = "Grep project" })
map("n", "<leader>pw", action("workbench.action.findInFiles"), { desc = "Grep word under cursor" })
map("n", "<leader>pb", action("workbench.action.showAllEditors"), { desc = "Open editors" })
map("n", "<leader>po", action("workbench.action.openRecent"), { desc = "Recent files" })
map("n", "<leader>pk", action("workbench.action.openGlobalKeybindings"), { desc = "Keybindings" })
map("n", "<leader>pd", action("workbench.actions.view.problems"), { desc = "Diagnostics" })
map("n", "<leader>pt", action("todo-tree.tree.focus"), { desc = "Find TODOs (needs Todo Tree ext)" })
map("n", "<leader>/", action("actions.find"), { desc = "Search in file" })

-- File explorer (nvim-tree's slot)
map("n", "<leader>pv", action("workbench.view.explorer"), { desc = "Toggle file explorer" })
map("n", "<leader>pV", action("workbench.files.action.showActiveFileInExplorer"), { desc = "Reveal current file" })

-- ---------------------------------------------------------------------------
-- LSP
--
-- In the terminal these are bound per-buffer on LspAttach. Here VS Code's own
-- language clients are always present, so bind them unconditionally.
-- ---------------------------------------------------------------------------
map("n", "gd", action("editor.action.revealDefinition"), { desc = "Go to definition" })
map("n", "gr", action("editor.action.goToReferences"), { desc = "Go to references" })
map("n", "gI", action("editor.action.goToImplementation"), { desc = "Go to implementation" })
map("n", "gy", action("editor.action.goToTypeDefinition"), { desc = "Go to type definition" })
map("n", "gD", action("editor.action.revealDeclaration"), { desc = "Go to declaration" })
map("n", "K", action("editor.action.showHover"), { desc = "Hover documentation" })
map("n", "<leader>rn", action("editor.action.rename"), { desc = "Rename symbol" })
map({ "n", "v" }, "<leader>ca", action("editor.action.quickFix"), { desc = "Code action" })
map("n", "<leader>ls", action("workbench.action.gotoSymbol"), { desc = "Document symbols" })
map("n", "<leader>lS", action("workbench.action.showAllSymbols"), { desc = "Workspace symbols" })
map("n", "<leader>th", action("editor.action.toggleInlayHints"), { desc = "Toggle inlay hints" })

-- Peek variants -- closer to Telescope's preview than a hard jump.
map("n", "<leader>lp", action("editor.action.peekDefinition"), { desc = "Peek definition" })
map("n", "<leader>lr", action("editor.action.referenceSearch.trigger"), { desc = "Peek references" })

-- ---------------------------------------------------------------------------
-- Diagnostics -- overrides the vim.diagnostic.* maps from keymaps.lua, which
-- would silently do nothing here (no Neovim LSP client is attached).
-- ---------------------------------------------------------------------------
map("n", "]d", action("editor.action.marker.next"), { desc = "Next diagnostic" })
map("n", "[d", action("editor.action.marker.prev"), { desc = "Previous diagnostic" })
map("n", "<leader>e", action("editor.action.showHover"), { desc = "Show diagnostic under cursor" })
map("n", "<leader>q", action("workbench.actions.view.problems"), { desc = "Problems panel" })
map("n", "<leader>xx", action("workbench.actions.view.problems"), { desc = "Diagnostics (project)" })
map("n", "<leader>xs", action("outline.focus"), { desc = "Symbol outline" })

-- ---------------------------------------------------------------------------
-- Format (conform's slot)
-- ---------------------------------------------------------------------------
map("n", "<leader>f", action("editor.action.formatDocument"), { desc = "Format buffer" })
map("v", "<leader>f", action("editor.action.formatSelection"), { desc = "Format selection" })

-- ---------------------------------------------------------------------------
-- Git (gitsigns / fugitive slot -> VS Code SCM)
-- ---------------------------------------------------------------------------
map("n", "]h", action("workbench.action.editor.nextChange"), { desc = "Next hunk" })
map("n", "[h", action("workbench.action.editor.previousChange"), { desc = "Previous hunk" })
map("n", "<leader>gp", action("editor.action.dirtydiff.next"), { desc = "Preview hunk" })
map("n", "<leader>gs", action("git.stageSelectedRanges"), { desc = "Stage hunk" })
map("n", "<leader>gr", action("git.revertSelectedRanges"), { desc = "Reset hunk" })
map("v", "<leader>gs", action("git.stageSelectedRanges"), { desc = "Stage selection" })
map("v", "<leader>gr", action("git.revertSelectedRanges"), { desc = "Reset selection" })
map("n", "<leader>gS", action("git.stage"), { desc = "Stage file" })
map("n", "<leader>gd", action("git.openChange"), { desc = "Diff against index" })
map("n", "<leader>gg", action("workbench.view.scm"), { desc = "Source control" })
map("n", "<leader>gb", action("gitlens.toggleFileBlame"), { desc = "Blame (needs GitLens ext)" })

-- ---------------------------------------------------------------------------
-- Debug (nvim-dap's slot -> VS Code's debugger, which is the original)
-- ---------------------------------------------------------------------------
map("n", "<leader>db", action("editor.debug.action.toggleBreakpoint"), { desc = "Toggle breakpoint" })
map("n", "<leader>dB", action("editor.debug.action.conditionalBreakpoint"), { desc = "Conditional breakpoint" })
map("n", "<leader>dc", action("workbench.action.debug.continue"), { desc = "Continue" })
map("n", "<leader>di", action("workbench.action.debug.stepInto"), { desc = "Step into" })
map("n", "<leader>do", action("workbench.action.debug.stepOver"), { desc = "Step over" })
map("n", "<leader>dO", action("workbench.action.debug.stepOut"), { desc = "Step out" })
map("n", "<leader>dt", action("workbench.action.debug.stop"), { desc = "Terminate" })
map("n", "<leader>dr", action("workbench.action.debug.restart"), { desc = "Restart" })
map("n", "<leader>du", action("workbench.view.debug"), { desc = "Debug view" })

-- ---------------------------------------------------------------------------
-- Terminal (toggleterm's slot)
-- ---------------------------------------------------------------------------
map("n", "<leader>tt", action("workbench.action.terminal.toggleTerminal"), { desc = "Toggle terminal" })
map("n", "<leader>tv", action("workbench.action.createTerminalEditorSide"), { desc = "Terminal (side)" })

-- ---------------------------------------------------------------------------
-- Comments -- VS Code owns gc/gcc here. `vim.g.vscode_gc = false` would hand
-- them back to a Neovim plugin, but we have none loaded, so leave as is.
-- ---------------------------------------------------------------------------

-- Folding: VS Code's folds and Neovim's disagree, so route za/zR/zM to VS Code.
map("n", "za", action("editor.toggleFold"), { desc = "Toggle fold" })
map("n", "zR", action("editor.unfoldAll"), { desc = "Open all folds" })
map("n", "zM", action("editor.foldAll"), { desc = "Close all folds" })
