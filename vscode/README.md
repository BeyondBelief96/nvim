# Using this config inside VS Code

At work you use VS Code. This directory lets you keep the same motions,
leader keys and editing habits there, without maintaining a second config by
hand.

The approach: the [`vscode-neovim`][ext] extension embeds a **real Neovim
process** inside VS Code. It loads this exact repo. `init.lua` detects it
(`vim.g.vscode`) and takes a short path — options and keymaps load, everything
in `lua/plugins/` is skipped — then `lua/core/vscode.lua` re-points the
Neovim-UI keymaps at the equivalent VS Code commands.

[ext]: https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim

```
             terminal nvim                    VS Code
             ─────────────                    ───────
init.lua ──> core/options.lua  ─── same ───>  core/options.lua
             core/keymaps.lua  ─── same ───>  core/keymaps.lua
             core/autocmds.lua                core/vscode.lua  (keymap overrides)
             core/lazy.lua                    ─ skipped ─
               └ lua/plugins/*                  VS Code's own LSP, picker,
                 (LSP, telescope, dap, …)       explorer, git, debugger
```

**Why skip the plugins?** VS Code already has an LSP client, completion,
fuzzy finder, file tree, git gutter, terminal and debugger. Running Neovim's
copies alongside means two completion popups, two sets of diagnostics and two
things fighting over the same keys. So VS Code owns the IDE layer; Neovim owns
text editing. That is the whole trade.

---

## Setup

### 1. Install Neovim on the machine

The extension needs a real `nvim` binary, v0.10 or newer.

| Where | How |
| --- | --- |
| macOS | `brew install neovim` |
| Ubuntu/Debian | `sudo apt install neovim` (check `nvim --version`; use the [official release][rel] if it is older than 0.10) |
| Windows | `winget install Neovim.Neovim` |
| WSL | Install inside WSL and set `"vscode-neovim.useWSL": true` |

[rel]: https://github.com/neovim/neovim/releases

If your work machine won't let you install binaries, skip to
[Fallback: VSCodeVim](#fallback-vscodevim) below.

### 2. Clone this config where Neovim expects it

```bash
# Linux / macOS / WSL
git clone <this-repo> ~/.config/nvim

# Windows (PowerShell)
git clone <this-repo> $env:LOCALAPPDATA\nvim
```

Then run `nvim` once in a terminal and let lazy.nvim install everything. This
is worth doing even if you only ever use VS Code — it verifies the config is
healthy, and gives you a working terminal editor for SSH and git commit
messages.

### 3. Install the extensions

```bash
code --install-extension asvetliakov.vscode-neovim
code --install-extension sainnhe.gruvbox-material          # matches the terminal theme
code --install-extension esbenp.prettier-vscode            # replaces conform + prettierd
code --install-extension dbaeumer.vscode-eslint            # replaces the eslint LSP
code --install-extension oxc.oxc-vscode                    # replaces oxlint + oxfmt
code --install-extension llvm-vs-code-extensions.vscode-clangd   # replaces clangd LSP
code --install-extension eamodio.gitlens                   # replaces fugitive/gitsigns blame
code --install-extension Gruntfuggly.todo-tree             # replaces todo-comments.nvim
```

TypeScript, JSON, HTML/CSS and Emmet are built into VS Code — no equivalent of
`ts_ls`, `jsonls`, `html`, `cssls` or `emmet_language_server` needed. The
debugger replaces `nvim-dap`, `codelldb` and `js-debug-adapter` outright.

> **Note:** the clangd extension conflicts with Microsoft's C/C++ IntelliSense.
> `settings.json` here already sets `"C_Cpp.intelliSenseEngine": "disabled"`.

### 4. Merge the settings

Open `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)** and merge in
[`settings.json`](settings.json). Then `Ctrl+Shift+P` → **Preferences: Open
Keyboard Shortcuts (JSON)** and merge in [`keybindings.json`](keybindings.json).

Check `vscode-neovim.neovimExecutablePaths.*` matches your `which nvim`.

### 5. Restart VS Code

Open a file and press `d` `d` in normal mode. If the line deletes, you're done.

---

## How the Ctrl keys are split

This is the part you asked about, and it's the setting most worth
understanding.

`vscode-neovim` sends a key to Neovim **only if you list it**. Everything else
stays a normal VS Code binding. That default is the right way round — you keep
VS Code's chords unless you opt out.

The lists in `settings.json` give Neovim only the keys where Vim's meaning is
clearly better:

| Neovim keeps | Why |
| --- | --- |
| `Ctrl+D` / `Ctrl+U` | Half-page scroll (`keymaps.lua` adds the `zz` centring) |
| `Ctrl+O` / `Ctrl+I` | Jump list — how you get back after `gd` |
| `Ctrl+R` | Redo |
| `Ctrl+V` | Visual block — VS Code has no real equivalent |
| `Ctrl+E` / `Ctrl+Y` | Scroll one line |
| `Ctrl+A` / `Ctrl+X` | Increment / decrement number |

| VS Code keeps | What it does |
| --- | --- |
| `Ctrl+P` | Quick Open — same thing the terminal config binds it to |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+F` / `Ctrl+Shift+F` | Find / find in files |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+S` | Save |
| `Ctrl+W` | Close editor (use `<leader>w` for splits instead) |
| `Ctrl+K` | Chord prefix (`Ctrl+K Ctrl+S`, `Ctrl+K Z`, …) |
| `Ctrl+`` ` `` | Toggle terminal |
| `Ctrl+J` | Toggle panel |

To move a key across, edit `vscode-neovim.ctrlKeysForNormalMode` in your
settings — add the letter to give it to Neovim, remove it to give it back to
VS Code. No restart needed.

`Ctrl+J` / `Ctrl+K` are worth calling out: in the terminal config they're
quickfix navigation, but `Ctrl+K` is the prefix for a whole family of VS Code
chords and losing it makes the editor feel broken. So `core/vscode.lua`
deletes those two maps, and `keybindings.json` instead makes them move the
selection in Quick Open and the suggestion widget — matching the Telescope
mappings in `lua/plugins/telescope.lua`.

---

## What changes, key by key

Almost everything is identical. These are the differences:

| Key | Terminal | VS Code |
| --- | --- | --- |
| `<leader><CR>` | Reload Lua config | Reload VS Code window |
| `<leader>w` | `<C-w>` window prefix | Only `wv` / `ws` / `wq` / `wo` |
| `<C-j>` / `<C-k>` | Quickfix prev/next | Given back to VS Code |
| `<leader>pk` | Telescope keymaps | VS Code keybindings editor |
| `<leader>pr` | Telescope resume | *(no equivalent)* |
| `<leader>ph` | Telescope help tags | *(no equivalent)* |
| `<leader>xl` `<leader>xq` | Trouble panels | *(use `<leader>xx` / `gr`)* |
| `<leader>m*` | cmake-tools | *(use the CMake Tools extension)* |
| `<leader>tf` | Toggle format on save | *(toggle `editor.formatOnSave`)* |

New in VS Code only: `<leader>lp` peek definition, `<leader>lr` peek
references, `<leader>wo` close other editors, `<leader>dr` restart debugging.

Everything else — `gd`, `gr`, `gI`, `gy`, `K`, `<leader>rn`, `<leader>ca`,
`<leader>f`, `<leader>th`, `[d` / `]d`, `[h` / `]h`, the whole `<leader>g`
git set, the whole `<leader>d` debug set, `<leader>pf` / `ps` / `pb`,
`<S-h>` / `<S-l>` — behaves the same.

---

## Type inference

Identical to the terminal setup, because it's the same tsserver underneath.
`K` shows the hover with the inferred type; `settings.json` turns on the same
inlay hints as the `ts_inlay` table in `lua/plugins/lsp.lua`, including
`variableTypes` for inline `const x: string` ghost text. `<leader>th` toggles
them.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Unable to start nvim" | `vscode-neovim.neovimExecutablePaths.*` is wrong. Compare with `which nvim` / `where nvim`. |
| Neovim starts but no keymaps | The extension found a *different* config. Check `vscode-neovim.neovimInitVimPaths.*`, or run `:echo $MYVIMRC` via the extension's `Show Neovim Messages` command. |
| Two completion popups | A plugin is loading anyway — the `vim.g.vscode` branch in `init.lua` isn't being hit. Check with `:lua print(vim.g.vscode)`. |
| Laggy cursor in normal mode | Set `"editor.cursorSmoothCaretAnimation": "off"` (already in `settings.json`). |
| `Ctrl+P` opens something odd | Remove `"p"` from `vscode-neovim.ctrlKeysForNormalMode`. |
| Esc doesn't leave insert mode | The `vscode-neovim.escape` binding in `keybindings.json` didn't merge. |
| Slow startup under WSL | Set `"vscode-neovim.useWSL": true` and use the Linux `nvim`, not a Windows one. |

---

## Fallback: VSCodeVim

If you genuinely can't install `nvim` — a locked-down work laptop, most
likely — use [`VSCodeVim`][vv] instead and merge
[`settings.vscodevim.json`](settings.vscodevim.json).

[vv]: https://marketplace.visualstudio.com/items?itemName=vscodevim.vim

Be clear about the cost: VSCodeVim is a reimplementation of Vim in TypeScript.
It never reads `init.lua`. Every keymap in that file is a hand-maintained
duplicate of `lua/core/keymaps.lua` and `lua/core/vscode.lua`, and **the two
will drift** — if you change a keymap in the Lua config, nothing updates the
JSON for you. Macros, registers and the more obscure text objects also behave
slightly differently.

It does have one advantage: `vim.surround` and its built-in easymotion/sneak
mean you don't need extensions for those. And the Ctrl-key model is inverted —
it grabs keys by default, so `vim.handleKeys` lists what to give *back*.

The editor, TypeScript and formatting sections of `settings.json` apply to
both extensions; only the `vim.*` keys differ.
