# This config's keybindings in VS Code

Two files to paste. No Neovim binary, no cloning this repo anywhere special.

## Setup

1. `code --install-extension vscodevim.vim`
2. `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)** → merge in
   [`settings.json`](settings.json)
3. `Ctrl+Shift+P` → **Preferences: Open Keyboard Shortcuts (JSON)** → merge in
   [`keybindings.json`](keybindings.json)

Check it: press `d` `d` in normal mode, then `<Space>` `p` `f` for Quick Open.

## Ctrl keys

Vim keeps `C-d` `C-u` (half page, centred), `C-o` `C-i` (jump list), `C-r`
(redo), `C-v` (visual block), `C-e` `C-y`, `C-a` `C-x` (inc/dec number).

VS Code keeps `C-p` `C-f` `C-b` `C-n` `C-s` `C-w` `C-k` and ``C-` `` — the list
in `vim.handleKeys`. Add a key there with `false` to hand it back to VS Code.

`C-h` and `C-l` stay with Vim and are mapped to pane navigation -- see below.

## Leader maps

Leader is `<Space>`, same as the terminal config.

| Key | Action |
| --- | --- |
| `gd` `gr` `gI` `K` | definition, references, implementations, hover |
| `<leader>rn` / `<leader>ca` | rename / code action |
| `]d` `[d` | next / previous diagnostic |
| `<leader>pf` `<leader>ps` `<leader>pb` `<leader>pv` | files, grep, buffers, explorer |
| `<leader>f` | format (document, or selection in visual) |
| `H` / `L` | previous / next editor tab |
| `<leader>wv` `<leader>ws` `<leader>wq` | vsplit, split, close |
| `<leader>gg` / `]h` `[h` | source control / next, previous hunk |

## Moving between editor, file tree and terminal

No mouse needed. Vim keymaps only fire inside an editor, so the outbound hops
live in `settings.json` and the return legs in `keybindings.json`.

| From | To | Key |
| --- | --- | --- |
| editor | file tree | `<leader>pv`, or `<leader>pV` to land on the current file |
| editor | pane left / right | `<C-h>` / `<C-l>` — steps across editor groups, then out into the sidebar or panel |
| editor | terminal | `<leader>tt` (or ``C-` ``); `<leader>tv` opens one beside the editor |
| file tree | editor | `Esc`, or `Enter` to open the file under the cursor |
| file tree | pane left / right | `<C-h>` / `<C-l>`, same as in the editor |
| tree, search, SCM | editor | `C-;` |
| terminal | editor | `C-;`, or ``C-` `` to hide the panel on the way out |

`C-;` rather than `C-l` for the terminal: `C-h` is backspace and `C-l` is
clear-screen to a shell, so neither is safe to steal there. Any key bound under
`terminalFocus` also needs its command in
`terminal.integrated.commandsToSkipShell` or the shell swallows it — see the
list near the bottom of `settings.json`.

## Optional extras

Not needed for Vim keys — add if you want the terminal setup's look and tooling:
`sainnhe.gruvbox-material` (then `"workbench.colorTheme": "Gruvbox Material Dark"`),
`esbenp.prettier-vscode`, `dbaeumer.vscode-eslint`, `llvm-vs-code-extensions.vscode-clangd`.

VSCodeVim never reads `init.lua` — if you change a keymap in `lua/core/keymaps.lua`,
change it here too.
