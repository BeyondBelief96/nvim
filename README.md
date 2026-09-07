# nvim

A Neovim config aimed at VS Code parity — real type checking, linting,
autocomplete, formatting and debugging — for **TypeScript/JavaScript**,
**HTML/CSS**, and **C++/CMake**. One repo, clone it on any machine.

Built on Neovim's own LSP client (0.11+ `vim.lsp.config` API), so there's no
CoC/Node layer between you and the editor.

---

## Install

Works on Linux, macOS, Windows via WSL2, and native Windows.

### Linux, macOS, WSL2

```bash
git clone https://github.com/<you>/nvim.git ~/.config/nvim
~/.config/nvim/bootstrap.sh
```

`bootstrap.sh` is idempotent. It installs the system packages (compiler
toolchain, cmake, ripgrep, fd, clang), a recent Neovim if yours is too old,
Node via `nvm`, a JetBrainsMono Nerd Font, then syncs all plugins and language
servers headlessly. It will ask for `sudo` once for the package manager step.

On WSL the font matters more than it looks: your terminal is a Windows
application, so it renders glyphs from *Windows*-installed fonts. Installing
into `~/.local/share/fonts` does nothing for it. `bootstrap.sh` handles both
sides automatically — you still have to pick the font yourself, below.

### Native Windows (no WSL)

```powershell
git clone https://github.com/<you>/nvim.git $env:LOCALAPPDATA\nvim
& $env:LOCALAPPDATA\nvim\bootstrap.ps1
```

`bootstrap.ps1` is the Windows counterpart to `bootstrap.sh`: same shape, same
idempotence. It installs Neovim, Git, PowerShell 7, ripgrep, fd, LLVM/clang,
CMake, Ninja and Node LTS through `winget`, installs the Nerd Font per-user (no
admin rights), then runs the same three headless sync steps. Open a **new**
terminal afterwards so it picks up the PATH changes.

If PowerShell refuses to run the script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $env:LOCALAPPDATA\nvim\bootstrap.ps1
```

Three things are worth knowing:

- **Config path.** Windows Neovim reads `%LOCALAPPDATA%\nvim`, not
  `~/.config/nvim`. Cloning straight into it is simplest; if you keep the repo
  elsewhere, `bootstrap.ps1` creates a directory *junction* into place.
  Junctions need neither admin rights nor Developer Mode — plain symlinks do.
- **Everything is per-user.** No step needs an elevated shell. `winget` may
  ask for elevation on individual packages; that's the vendor installer, not
  this script.
- **The same repo drives all three environments.** Nothing here is forked per
  platform: `lua/core/platform.lua` reports which machine you're on and the
  four places that genuinely have to differ read it (see below).

#### What actually differs on Windows

| | Elsewhere | Native Windows | Why |
|---|---|---|---|
| telescope-fzf-native | `make` | CMake build | the upstream Makefile assumes a POSIX toolchain |
| Terminal (`<C-\>`, `<leader>tt`) | `$SHELL` | `pwsh`, else `powershell` | Neovim inherits `cmd.exe` as `'shell'` otherwise |
| CMake build tree | `build/<BuildType>/`, symlinked to the root | plain `build/` | the symlink needs Developer Mode; `build/` is somewhere clangd already looks |
| DAP adapters | spawned by name | `.cmd` shims routed via `cmd.exe` | `CreateProcess` can't run a batch file directly |

`'shell'` itself is left as `cmd.exe`. Only the toggleterm terminal is switched
to PowerShell — changing `'shell'` globally would also change how vim-fugitive
and every other `system()` caller quotes its arguments, and their Windows
escaping is written against `cmd.exe`.

#### C++ on native Windows

Treesitter builds every parser from source, so a C compiler has to be on PATH;
`bootstrap.ps1` installs LLVM for that, which also gets you `clang` and
`clang-format`. `cmake-tools` passes `-G Ninja`, so CMake picks up whichever
compiler it finds first — `clang` from LLVM, or MSVC's `cl.exe` if you launch
Neovim from a Developer Command Prompt (or run `vcvars64.bat` first).

`codelldb` debugs clang/MinGW-built binaries fine. For MSVC-built ones its PDB
support is patchy; if you hit that, install `cpptools` via `:Mason` and add a
`cppvsdbg` configuration in `lua/plugins/local.lua`.

### Setting up WSL2

If you'd rather use WSL: install WSL2 + Ubuntu (`wsl --install -d Ubuntu` in an
admin PowerShell), then run the Linux steps above inside it. Work on files
under the Linux filesystem (`~/…`), not `/mnt/c/…` — cross-filesystem I/O is
slow enough that LSP and file watching noticeably drag.

### Afterwards, on every platform

**Set your terminal font** or the icons render as boxes. The font installs
under the family name **`JetBrainsMono NF`** — that's what to look for in the
picker, not "JetBrainsMono Nerd Font". In Windows Terminal:
Settings → your profile → Appearance → Font face → `JetBrainsMono NF`.

Then open `nvim` and run `:checkhealth`.

---

## Layout

```
init.lua                  entry point; sets leader, loads core/, branches on VS Code
lua/core/
  options.lua             editor settings (all built-in, no plugins)
  keymaps.lua             non-plugin keymaps
  autocmds.lua            format-on-save helpers, per-filetype indent, etc.
  vscode.lua              keymap overrides when running inside VS Code
  platform.lua            OS detection; read by the specs that must differ
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
bootstrap.sh              one-shot installer for Linux / macOS / WSL2
bootstrap.ps1             one-shot installer for native Windows
templates/                .clang-format, CMakeLists.txt, .clangd starters
vscode/                   settings + keybindings for using this config in VS Code
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
| — linting | `oxlint` | Used automatically in oxlint projects; see below |
| HTML | `html`, `emmet_language_server` | Emmet: type `div.foo>ul>li*3` then `<C-y>,` |
| CSS / SCSS | `cssls`, `tailwindcss` | |
| JSON / YAML | `jsonls`, `yamlls` | Schema validation |
| C / C++ | `clangd` | Needs `compile_commands.json` — see below |
| CMake | `neocmake` | |
| Lua | `lua_ls` + `lazydev` | Knows the Neovim API when editing this config |

Formatters: `prettierd` (web), `oxfmt` (web, opt-in per project — see below),
`clang-format` (C/C++), `stylua` (Lua). All installed by mason; `:Mason` to
browse or add more.

### oxlint vs ESLint

Both linters are installed, and the config picks per project so you never get
two linters fighting over the same buffer:

| Project has | Linters that attach |
|---|---|
| `.oxlintrc.json` / `oxlint.config.ts` only | oxlint |
| ESLint config only | eslint |
| Both | both |
| Neither | neither |

Detection walks up from the current file, so this works in monorepos where
different packages use different linters.

Two upstream quirks the config works around, worth knowing if you ever debug this:

- oxlint's shipped config doesn't set `workspace_required`, so with no oxlint
  config found it would still start rootless and attach to every JS/TS buffer.
  The config sets that flag.
- ESLint roots on a lockfile or `.git`, so it attaches to almost any JS project
  including oxlint-only ones. The config skips it when oxlint config is present
  and no ESLint config is.

**Fixes on save** apply for whichever linter attached. Note oxlint only applies
fixes it classifies as *safe* — `eqeqeq` and `no-debugger` are marked dangerous
upstream, so they're reported but never auto-applied. Run `oxlint
--fix-dangerously` from a shell if you want those. Set `fixKind` in the oxlint
`settings` block in `lua/plugins/lsp.lua` to change this.

oxlint uses *pull* diagnostics, so its messages show `source = oxc`.

### oxfmt vs Prettier

Same idea on the formatting side, and also opt-in per project:

| Project has | Formatter used |
|---|---|
| `.oxfmtrc.json`, `.oxfmtrc.jsonc`, or `oxfmt.config.ts` | `oxfmt` |
| anything else | `prettierd`, falling back to `prettier` |

Detection walks upward from the current file, so a monorepo can mix the two
across packages. Nothing changes for projects that have never heard of oxc.

oxfmt is wired up as a **conform formatter only, not a language server.**
mason-lspconfig would otherwise auto-enable it just because the package is
installed, and it declares no `workspace_required` — so it would attach to
every JS/TS buffer even with no oxfmt config. It's excluded from
`automatic_enable` in `lua/plugins/lsp.lua` for that reason.

To switch a project over, drop an `.oxfmtrc.json` at its root — `{}` is enough
to opt in with oxc's defaults.

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

## VS Code

If you use VS Code at work, this config comes with you. The
[`vscode-neovim`](https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim)
extension runs a real Neovim inside VS Code and loads this repo: `init.lua`
detects it via `vim.g.vscode`, keeps `core/options.lua` and `core/keymaps.lua`,
skips everything in `lua/plugins/`, and `core/vscode.lua` re-points the
Neovim-UI keymaps at the equivalent VS Code commands. VS Code keeps `Ctrl+P`,
`Ctrl+Shift+P`, `Ctrl+F` and the rest of its defaults.

Setup, the full keymap diff, and a VSCodeVim fallback for machines where you
can't install `nvim`: **[`vscode/README.md`](vscode/README.md)**.

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
| Windows: nvim starts with no plugins | Neovim is reading a different config. `:echo stdpath('config')` must print your repo (or the junction to it) under `%LOCALAPPDATA%\nvim`. |
| Windows: Treesitter parsers fail to build | No C compiler on PATH. `winget install --id LLVM.LLVM`, then add `C:\Program Files\LLVM\bin` to PATH and re-run `:TSUpdateSync`. |
| Windows: mason installs fail | mason needs PowerShell 7. `winget install --id Microsoft.PowerShell`, open a new terminal, retry. Node-based servers also need `node` on PATH. |
| Windows: `<C-\>` opens cmd.exe | `pwsh` wasn't on PATH when Neovim started. Install it and restart Neovim — `lua/plugins/ui.lua` picks it up automatically. |
| Windows: clangd can't find `compile_commands.json` | On Windows the build tree is plain `build/` and there is no root symlink (see above). Run `<leader>mg` (CMakeGenerate) at least once. |
| No completions or diagnostics | `:LspInfo` — is a server attached? `:Mason` — is it installed? |
| clangd errors on every `#include` | No `compile_commands.json`; see above. |
| Treesitter parser build fails | Missing C compiler. Re-run `bootstrap.sh` (or `bootstrap.ps1`). |
| `Telescope live_grep` finds nothing | `ripgrep` not installed. |
| Node servers won't start under WSL | Windows `node.exe` is shadowing nvm's. Check `which node` — it must not be under `/mnt/c`. |
| Something's broken after an update | `git checkout lazy-lock.json && nvim -c 'Lazy restore'` to roll plugins back. |

`:checkhealth` covers most of these.
