# nvim

A Neovim config aimed at VS Code parity — real type checking, linting,
autocomplete, formatting and debugging — for **TypeScript/JavaScript**,
**HTML/CSS**, and **C++/CMake**. One repo, clone it on any machine.

Built on Neovim's own LSP client (0.11+ `vim.lsp.config` API), so there's no
CoC/Node layer between you and the editor.

---

## Install

Works on Linux, macOS, and Windows **via WSL2**.

```bash
git clone https://github.com/<you>/nvim.git ~/.config/nvim
~/.config/nvim/bootstrap.sh
```

`bootstrap.sh` is idempotent. It installs the system packages (compiler
toolchain, cmake, ripgrep, fd, clang), a recent Neovim if yours is too old,
Node via `nvm`, a JetBrainsMono Nerd Font, then syncs all plugins and language
servers headlessly. It will ask for `sudo` once for the package manager step.

Afterwards, **set your terminal font** or the icons render as boxes. The font
installs as family name **`JetBrainsMono NF`** — that's what to look for in the
font picker, not "JetBrainsMono Nerd Font".

On WSL this matters more than it looks: your terminal is a Windows application,
so it renders glyphs from *Windows*-installed fonts. Installing into
`~/.local/share/fonts` does nothing for it. `bootstrap.sh` handles both sides
automatically, but you still have to pick the font yourself:
Windows Terminal → Settings → your profile → Appearance → Font face →
`JetBrainsMono NF`.

Then open `nvim` and run `:checkhealth`.

### Windows note

This config targets WSL2, not native Windows Neovim. Install WSL2 + Ubuntu
(`wsl --install -d Ubuntu` in an admin PowerShell), then run the steps above
inside it. Work on files under the Linux filesystem (`~/…`), not `/mnt/c/…` —
cross-filesystem I/O is slow enough that LSP and file watching noticeably drag.

---

## Layout

```
init.lua                  entry point; sets leader, then loads core/
lua/core/
  options.lua             editor settings (all built-in, no plugins)
  keymaps.lua             non-plugin keymaps
  autocmds.lua            format-on-save helpers, per-filetype indent, etc.
  lazy.lua                bootstraps lazy.nvim, imports lua/plugins/
lua/plugins/
  colorscheme.lua         gruvbox-material
  lsp.lua                 mason + language servers + diagnostics + LSP keymaps
  completion.lua          blink.cmp autocomplete and snippets
  treesitter.lua          syntax tree: highlighting, indent, text objects
  telescope.lua           fuzzy finding (replaces the old fzf.vim setup)
  formatting.lua          conform.nvim, format on save
  cpp.lua                 clangd extras + CMake build/run/debug
  dap.lua                 debugging (codelldb for C++, js-debug for Node)
  git.lua                 gitsigns + fugitive
  ui.lua                  file tree, statusline, which-key, terminal
  editing.lua             autopairs, autotag, surround, colour preview
  local.lua.example       copy to local.lua for machine-specific overrides
bootstrap.sh              one-shot installer
templates/                .clang-format, CMakeLists.txt, .clangd starters
legacy/init.vim           the original vimscript config, for reference
```

Plugin *versions* are pinned in `lazy-lock.json`, which is committed. Cloning
this repo on a second machine gives you byte-identical plugin versions. Run
`:Lazy update` to move forward, and commit the changed lockfile.

---

## Keymaps

Leader is **Space**. Press `<Space>` and pause — which-key lists everything.

### Carried over from the old config

| Key | Action |
|---|---|
| `<leader>pv` | File explorer (was `:Vex`, now nvim-tree) |
| `<leader><CR>` | Reload config |
| `<leader>w` | Window prefix (`<leader>wv`, `<leader>ws`, `<leader>wq`, …) |
| `<C-p>` | Find git files |
| `<leader>pf` | Find files |
| `<C-j>` / `<C-k>` | Previous / next quickfix item |

### Find (`<leader>p`)

| Key | Action |
|---|---|
| `<leader>ps` | Grep the project (live) |
| `<leader>pw` | Grep the word under the cursor |
| `<leader>pb` | Buffers |
| `<leader>po` | Recent files |
| `<leader>pd` | Diagnostics |
| `<leader>pk` | Search keymaps |
| `<leader>pt` | TODO/FIXME comments |
| `<leader>pr` | Reopen last picker |
| `<leader>/` | Fuzzy-search inside the current buffer |

### LSP

| Key | Action |
|---|---|
| `gd` / `gr` | Definition / references |
| `gI` / `gy` | Implementation / type definition |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol (project-wide) |
| `<leader>ca` | Code action / quick fix |
| `<leader>ls` / `<leader>lS` | Document / workspace symbols |
| `<leader>th` | Toggle inlay hints |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>e` | Show diagnostic under cursor |
| `<leader>xx` | Project diagnostics list (the "Problems" panel) |

### Format

| Key | Action |
|---|---|
| `<leader>f` | Format buffer or selection |
| `<leader>tf` | Toggle format-on-save |

### C++ / CMake (`<leader>m` for make, `<leader>c` for clangd)

| Key | Action |
|---|---|
| `<leader>mg` | CMake generate |
| `<leader>mb` | CMake build |
| `<leader>mr` | CMake run |
| `<leader>md` | CMake debug |
| `<leader>mt` / `<leader>ms` | Select build type / target |
| `<leader>ch` | Switch between source and header |
| `<leader>ct` | Type hierarchy |

### Debug (`<leader>d`, plus VS Code's function keys)

| Key | Action |
|---|---|
| `<F5>` / `<S-F5>` | Start-continue / stop |
| `<F9>` | Toggle breakpoint |
| `<F10>` / `<F11>` / `<S-F11>` | Step over / into / out |
| `<leader>dB` | Conditional breakpoint |
| `<leader>du` | Toggle debug UI |
| `<leader>dh` | Inspect value under cursor |

### Git (`<leader>g`)

| Key | Action |
|---|---|
| `<leader>gg` | Git status (fugitive) |
| `<leader>gs` / `<leader>gr` | Stage / reset hunk (works on a visual selection too) |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `[h` / `]h` | Previous / next hunk |

### Editing

`<C-space>` grows a treesitter selection, `<BS>` shrinks it.
`af`/`if`, `ac`/`ic`, `aa`/`ia` select a function, class, or argument.
`]f`/`[f` jump between functions. `cs"'`, `ysiw"`, `ds(` for surround.
`<C-\>` toggles a floating terminal (works from inside the terminal too),
`<leader>tt` opens one in a horizontal split, `<leader>tv` in a vertical split.
`<Esc><Esc>` leaves terminal-insert mode.

---

## Languages

| Language | Server | Notes |
|---|---|---|
| TypeScript / JavaScript | `ts_ls` | Type checking, refactors, inlay hints |
| — linting | `eslint` | Auto-fixes on save if the project has an ESLint config |
| HTML | `html`, `emmet_language_server` | Emmet: type `div.foo>ul>li*3` then `<C-y>,` |
| CSS / SCSS | `cssls`, `tailwindcss` | |
| JSON / YAML | `jsonls`, `yamlls` | Schema validation |
| C / C++ | `clangd` | Needs `compile_commands.json` — see below |
| CMake | `neocmake` | |
| Lua | `lua_ls` + `lazydev` | Knows the Neovim API when editing this config |

Formatters: `prettierd` (web), `clang-format` (C/C++), `stylua` (Lua).
All installed by mason; `:Mason` to browse or add more.

### Getting clangd to work

clangd needs to know your compiler flags. Without that you get "file not found"
on every `#include`. Pick one:

- **CMake** — `<leader>mg` (CMakeGenerate). This config passes
  `-DCMAKE_EXPORT_COMPILE_COMMANDS=1` and symlinks the resulting
  `compile_commands.json` into the project root. Nothing else to do.
- **Make or other** — `bear -- make` wraps a build and records the flags.
- **Single files / quick tests** — a `compile_flags.txt` at the project root
  with one flag per line, e.g. `-std=c++20` then `-Iinclude`.

`templates/` has starter `CMakeLists.txt`, `.clang-format`, and `.clangd` files.

---

## Customising

- **Add a language server**: add its mason name to `ensure_installed` in
  `lua/plugins/lsp.lua`, then `:Lazy reload nvim-lspconfig`. Per-server options
  go in a `vim.lsp.config("name", { … })` call in the same file.
- **Swap `ts_ls` for `vtsls`** (better monorepo handling, richer code actions):
  change both the `ensure_installed` entry and the `vim.lsp.config` call.
- **Machine-specific settings**: `cp lua/plugins/local.lua.example
  lua/plugins/local.lua`. That path is gitignored.
- **Change the colourscheme**: `lua/plugins/colorscheme.lua`, and update the
  fallback list in `lua/core/lazy.lua`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Boxes instead of icons | Terminal font isn't set to `JetBrainsMono NF`. On WSL the font must be installed on the *Windows* side — a WSL-only install is invisible to the terminal. |
| No completions or diagnostics | `:LspInfo` — is a server attached? `:Mason` — is it installed? |
| clangd errors on every `#include` | No `compile_commands.json`; see above. |
| Treesitter parser build fails | Missing C compiler. Re-run `bootstrap.sh`. |
| `Telescope live_grep` finds nothing | `ripgrep` not installed. |
| Node servers won't start under WSL | Windows `node.exe` is shadowing nvm's. Check `which node` — it must not be under `/mnt/c`. |
| Something's broken after an update | `git checkout lazy-lock.json && nvim -c 'Lazy restore'` to roll plugins back. |

`:checkhealth` covers most of these.
