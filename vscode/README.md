# Using this config's keybindings inside VS Code

VS Code's GUI, this repo's Vim motions and leader keys. Two ways to get there:

| | **VSCodeVim** *(documented below)* | **vscode-neovim** |
| --- | --- | --- |
| What it is | A Vim reimplementation in TypeScript | A real `nvim` process embedded in VS Code |
| Needs an `nvim` binary | No | Yes |
| Reads this repo's `init.lua` | **No** — keymaps are restated in JSON | Yes, directly |
| Setup | Paste two JSON files | Install nvim, clone this repo, paste two JSON files |
| Macros, registers, obscure text objects | Close, not exact | Exact — it *is* Vim |
| Keeps in sync with `lua/core/keymaps.lua` | No, by hand | Automatically |
| Bundled `surround` / `easymotion` | Yes, built in | No, but you don't need them |

Both give you the full VS Code GUI — explorer, IntelliSense, debugger, SCM.
The difference is only what interprets your keystrokes.

**This README documents the VSCodeVim path.** For vscode-neovim instead, use
[`settings.json`](settings.json) + [`keybindings.json`](keybindings.json) and
skip to [The vscode-neovim path](#the-vscode-neovim-path) at the bottom.

---

## The one thing to know first

VSCodeVim never reads `init.lua`. Every keymap in
[`settings.vscodevim.json`](settings.vscodevim.json) is a hand-maintained copy
of `lua/core/keymaps.lua` and `lua/core/vscode.lua`, and **the two will drift**
— if you change a keymap in the Lua config, nothing updates the JSON for you.

If you keep using terminal Neovim as well, treat that file as a checklist to
update in the same commit. If VS Code is now your only editor, this is a
non-issue: the JSON is the source of truth and the Lua config is just there for
SSH and `git commit` messages.

---

## Setup

### 1. Install the extensions

```bash
code --install-extension vscodevim.vim                           # the Vim layer
code --install-extension sainnhe.gruvbox-material                # matches the terminal theme
code --install-extension esbenp.prettier-vscode                  # replaces conform + prettierd
code --install-extension dbaeumer.vscode-eslint                  # replaces the eslint LSP
code --install-extension oxc.oxc-vscode                          # replaces oxlint + oxfmt
code --install-extension JohnnyMorganz.stylua                    # replaces the stylua formatter
code --install-extension llvm-vs-code-extensions.vscode-clangd   # replaces the clangd LSP
code --install-extension eamodio.gitlens                         # replaces fugitive/gitsigns blame
code --install-extension Gruntfuggly.todo-tree                   # replaces todo-comments.nvim
code --install-extension ms-vscode.cmake-tools                   # replaces cmake-tools.nvim
```

TypeScript, JSON, HTML/CSS and Emmet are built into VS Code — no equivalent of
`ts_ls`, `jsonls`, `html`, `cssls` or `emmet_language_server` needed. The
debugger replaces `nvim-dap`, `codelldb` and `js-debug-adapter` outright.

> **Note:** the clangd extension conflicts with Microsoft's C/C++ IntelliSense.
> `settings.vscodevim.json` already sets `"C_Cpp.intelliSenseEngine": "disabled"`.

### 2. Paste in the settings

`Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)** → merge in
[`settings.vscodevim.json`](settings.vscodevim.json).

That file is self-contained — Vim options, keymaps, editor settings,
TypeScript inlay hints, format-on-save, theme and clangd flags. Don't also
merge `settings.json`; that one is for vscode-neovim and the two conflict.

### 3. Paste in the keybindings

`Ctrl+Shift+P` → **Preferences: Open Keyboard Shortcuts (JSON)** → merge in
[`keybindings.vscodevim.json`](keybindings.vscodevim.json).

Small file: the Esc/IntelliSense fix, `j`/`k` navigation in the file tree, and
`Ctrl+J`/`Ctrl+K` in Quick Open.

### 4. Check it

Open a file, press `d` `d` in normal mode. If the line deletes, you're done.
Then try `<Space>` `p` `f` — Quick Open should appear.

You do **not** need to install Neovim or clone this repo anywhere special. The
two JSON files above are the entire VS Code setup.

---

## How the Ctrl keys are split

This is the setting most worth understanding.

VSCodeVim grabs Ctrl keys by default and `vim.handleKeys` lists the ones you
hand *back* to VS Code — the opposite of vscode-neovim, which is opt-in. The
list in `settings.vscodevim.json` gives Vim only the keys where Vim's meaning
is clearly better.

| Vim keeps | Why |
| --- | --- |
| `Ctrl+D` / `Ctrl+U` | Half-page scroll (remapped to add the `zz` centring) |
| `Ctrl+O` / `Ctrl+I` | Jump list — how you get back after `gd` |
| `Ctrl+R` | Redo |
| `Ctrl+V` | Visual block — VS Code has no real equivalent |
| `Ctrl+E` / `Ctrl+Y` | Scroll one line |
| `Ctrl+A` / `Ctrl+X` | Increment / decrement number |

| VS Code keeps | What it does |
| --- | --- |
| `Ctrl+P` | Quick Open — same thing the terminal config binds it to |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+F` | Find |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+S` | Save |
| `Ctrl+N` | New file |
| `Ctrl+T` | Go to symbol in workspace |
| `Ctrl+W` | Close editor (use `<leader>w` for splits instead) |
| `Ctrl+K` | Chord prefix (`Ctrl+K Ctrl+S`, `Ctrl+K Z`, …) |
| `` Ctrl+` `` | Toggle terminal |
| `Ctrl+J` | Toggle panel |

To move a key across, edit `vim.handleKeys` — remove the entry to give it to
Vim, add `"<C-x>": false` to give it back to VS Code. No restart needed.

### The three real losses

`vim.handleKeys` is global, not per-mode, so handing a key to VS Code takes it
from Vim in *every* mode:

- **`Ctrl+F` / `Ctrl+B`** — no page-forward / page-back. Use `Ctrl+D` twice.
- **`Ctrl+W` in insert mode** — no delete-word-backwards. Use `Ctrl+H` or Esc out.
- **`Ctrl+A`** is increment-number, so **no select-all**. Use `ggVG`, or add
  `"<C-a>": false` if you'd rather have select-all back.

`Ctrl+J` / `Ctrl+K` are worth calling out too: in the terminal config they're
quickfix navigation, but `Ctrl+K` is the prefix for a whole family of VS Code
chords and losing it makes the editor feel broken. So they go to VS Code, and
`keybindings.vscodevim.json` instead makes them move the selection in Quick
Open and the suggestion widget — matching the Telescope mappings in
`lua/plugins/telescope.lua`.

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
references, `<leader>wo` close other editors, `<leader>dr` restart debugging,
`<leader>tv` terminal to the side.

Everything else — `gd`, `gr`, `gI`, `gy`, `K`, `<leader>rn`, `<leader>ca`,
`<leader>f`, `<leader>th`, `[d` / `]d`, `[h` / `]h`, the whole `<leader>g`
git set, the whole `<leader>d` debug set, `<leader>pf` / `ps` / `pb`,
`<S-h>` / `<S-l>` — behaves the same.

`ys` / `cs` / `ds` work too: `"vim.surround": true` replaces nvim-surround.
Folding (`za`, `zR`, `zM`) is built in and drives VS Code's own folds.

### Emulations left off on purpose

Each of these VSCodeVim features would eat a key you already use. Turn one on
only if you also move the conflicting binding.

| Setting | Conflicts with |
| --- | --- |
| `vim.sneak` | `s` / `S` (substitute) |
| `vim.replaceWithRegister` | `gr` (go to references) |
| `vim.camelCaseMotion.enable` | `<leader>w` (window prefix) |

`vim.easymotion` is safe — it lives under `<leader><leader>`. Uncomment it in
`settings.vscodevim.json` if you want it.

---

## Type inference

Identical to the terminal setup, because it's the same tsserver underneath.
`K` shows the hover with the inferred type; the settings file turns on the same
inlay hints as the `ts_inlay` table in `lua/plugins/lsp.lua`, including
`variableTypes` for inline `const x: string` ghost text. `<leader>th` toggles
them.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No Vim at all | The extension is disabled for this workspace, or another Vim extension is fighting it. Only one of VSCodeVim / vscode-neovim may be enabled. |
| Esc needs two presses to leave insert | The `runCommands` binding in `keybindings.vscodevim.json` didn't merge, or your VS Code predates 1.77. |
| `Ctrl+P` opens something odd | `"<C-p>": false` is missing from `vim.handleKeys`. |
| `Ctrl+A` selects all instead of incrementing | Something else set `"<C-a>": false`. |
| Laggy cursor in normal mode | `"editor.cursorSmoothCaretAnimation": "off"` — but note it is *not* in `settings.vscodevim.json`, because VSCodeVim uses VS Code's own cursor and doesn't need it. Add it if you see lag anyway. |
| Two sets of diagnostics on C++ | `"C_Cpp.intelliSenseEngine": "disabled"` didn't merge. |
| Keymap works in the terminal but not here | Expected — see [the drift warning](#the-one-thing-to-know-first). Add it to `settings.vscodevim.json`. |
| Relative line numbers stay relative in insert mode | `"vim.smartRelativeLine": true` didn't merge. |

---

## The vscode-neovim path

If you later want the exact-Vim option, `vscode-neovim` embeds a real Neovim
process that loads **this repo** directly. `init.lua` detects it
(`vim.g.vscode`) and takes a short path — options and keymaps load, everything
in `lua/plugins/` is skipped — then `lua/core/vscode.lua` re-points the
Neovim-UI keymaps at the equivalent VS Code commands. No drift, because there
is only one source of truth.

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

**Why skip the plugins?** VS Code already has an LSP client, completion, fuzzy
finder, file tree, git gutter, terminal and debugger. Running Neovim's copies
alongside means two completion popups, two sets of diagnostics and two things
fighting over the same keys. So VS Code owns the IDE layer; Neovim owns text
editing. That is the whole trade.

Setup:

1. Install a real `nvim`, v0.10 or newer — `brew install neovim`,
   `sudo apt install neovim`, or `winget install Neovim.Neovim`. Under WSL,
   install it inside WSL and set `"vscode-neovim.useWSL": true`.
2. Clone this repo to `~/.config/nvim` (or `$env:LOCALAPPDATA\nvim` on
   Windows) and run `nvim` once to let lazy.nvim install everything.
3. `code --install-extension asvetliakov.vscode-neovim`, plus the same
   supporting extensions listed above (minus `vscodevim.vim`).
4. Merge [`settings.json`](settings.json) and
   [`keybindings.json`](keybindings.json) instead of the `.vscodevim` pair.
   Check `vscode-neovim.neovimExecutablePaths.*` matches your `which nvim`.

Only one Vim extension may be enabled at a time — disable `vscodevim.vim`
first, and remove its `vim.*` settings, or the two will both try to interpret
your keystrokes.
