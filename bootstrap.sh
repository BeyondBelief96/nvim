#!/usr/bin/env bash
#
# Bootstraps this Neovim config on a fresh machine (Linux, WSL, or macOS).
# Native Windows has its own equivalent: bootstrap.ps1.
#
#   git clone <your-repo> ~/.config/nvim
#   ~/.config/nvim/bootstrap.sh
#
# Idempotent -- safe to re-run. Installs system packages, Node (via nvm),
# a Nerd Font, and then syncs plugins and language servers headlessly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NVM_VERSION="v0.40.3"
NERD_FONT="JetBrainsMono"

# --- output helpers ---------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi
step() { printf "\n%s==> %s%s\n" "$BOLD" "$1" "$RESET"; }
ok()   { printf "  %s✓%s %s\n" "$GREEN" "$RESET" "$1"; }
warn() { printf "  %s!%s %s\n" "$YELLOW" "$RESET" "$1"; }
die()  { printf "  %s✗%s %s\n" "$RED" "$RESET" "$1" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- detect platform --------------------------------------------------------
OS="$(uname -s)"
IS_WSL=0
if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then IS_WSL=1; fi

PKG=""
case "$OS" in
  Darwin) PKG="brew" ;;
  Linux)
    if   have apt-get; then PKG="apt"
    elif have dnf;     then PKG="dnf"
    elif have pacman;  then PKG="pacman"
    elif have zypper;  then PKG="zypper"
    else die "No supported package manager found (apt/dnf/pacman/zypper)."
    fi
    ;;
  *) die "Unsupported OS: $OS. For native Windows use bootstrap.ps1; otherwise run this inside WSL2." ;;
esac

WSL_NOTE=""; if [ "$IS_WSL" = 1 ]; then WSL_NOTE=" (WSL)"; fi
step "Platform: ${OS}${WSL_NOTE} / package manager: $PKG"

# --- system packages --------------------------------------------------------
# neovim  : the editor itself (>= 0.11 required for the built-in LSP config API)
# git,curl,unzip : plugin + language-server downloads
# gcc/g++/make/cmake/ninja : C++ toolchain, and needed to build telescope-fzf-native
# ripgrep : Telescope live_grep backend
# fd      : fast file finding
# python3 : some language servers and treesitter parsers shell out to it
step "Installing system packages"
case "$PKG" in
  brew)
    have brew || die "Install Homebrew first: https://brew.sh"
    brew install neovim git curl unzip cmake ninja ripgrep fd python3 llvm || true
    ok "Homebrew packages installed (clang/clangd come from Xcode CLT or llvm)"
    ;;
  apt)
    sudo apt-get update
    sudo apt-get install -y \
      git curl wget unzip build-essential cmake ninja-build \
      ripgrep fd-find python3 python3-venv python3-pip \
      clang clangd clang-format gdb pkg-config fontconfig
    # Debian/Ubuntu ship fd as `fdfind`; give it its conventional name.
    if have fdfind && ! have fd; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      ok "Linked fdfind -> ~/.local/bin/fd"
    fi
    ok "apt packages installed"
    ;;
  dnf)
    sudo dnf install -y git curl wget unzip gcc gcc-c++ make cmake ninja-build \
      ripgrep fd-find python3 python3-pip clang clang-tools-extra gdb fontconfig
    ok "dnf packages installed"
    ;;
  pacman)
    sudo pacman -S --needed --noconfirm git curl wget unzip base-devel cmake ninja \
      ripgrep fd python python-pip clang gdb fontconfig
    ok "pacman packages installed"
    ;;
  zypper)
    sudo zypper install -y git curl wget unzip gcc gcc-c++ make cmake ninja \
      ripgrep fd python3 python3-pip clang gdb fontconfig
    ok "zypper packages installed"
    ;;
esac

# --- Neovim version ---------------------------------------------------------
# Distro repos often lag. This config needs >= 0.11 for vim.lsp.config().
step "Checking Neovim version"
install_nvim_appimage() {
  warn "Installing Neovim from the official release instead"
  local arch tarball url
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  tarball="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) tarball="nvim-linux-arm64.tar.gz" ;;
    *) die "No prebuilt Neovim for $arch -- build from source." ;;
  esac
  url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"
  mkdir -p "$HOME/.local"
  curl -fsSL "$url" | tar -xz -C "$HOME/.local" --strip-components=1
  ok "Neovim installed to ~/.local/bin/nvim"
}

if have nvim; then
  NVIM_VER="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  NVIM_MAJOR="${NVIM_VER%%.*}"; NVIM_MINOR="${NVIM_VER##*.}"
  if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 11 ]; then
    warn "Neovim $NVIM_VER is too old (need >= 0.11)"
    if [ "$PKG" = "brew" ]; then brew upgrade neovim; else install_nvim_appimage; fi
  else
    ok "Neovim $NVIM_VER"
  fi
else
  if [ "$PKG" = "brew" ]; then brew install neovim; else install_nvim_appimage; fi
fi

# --- Node.js via nvm --------------------------------------------------------
# Language servers for TS/JS/HTML/CSS are npm packages, so a working Node is
# required. Under WSL the Windows node.exe on $PATH will NOT work -- Linux
# Neovim cannot execute a Windows binary -- so we always install a Linux Node.
step "Setting up Node.js"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

node_is_windows() {
  have node && [[ "$(command -v node)" == /mnt/* ]]
}

if node_is_windows; then
  warn "Found Windows Node at $(command -v node) -- Linux Neovim cannot use it"
fi

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

if ! nvm ls --no-colors 2>/dev/null | grep -q "v[0-9]"; then
  nvm install --lts
  nvm alias default 'lts/*'
fi
nvm use default >/dev/null
ok "Node $(node --version) at $(command -v node)"

if node_is_windows; then
  warn "Windows Node still shadows nvm's. Add this to your shell rc AFTER any"
  warn "Windows PATH additions:  export PATH=\"\$NVM_DIR/versions/node/\$(node -v)/bin:\$PATH\""
fi

# --- Nerd Font --------------------------------------------------------------
# The icons in the statusline, file tree and completion menu need one.
step "Installing $NERD_FONT Nerd Font"
install_font() {
  local dir url tmp
  if [ "$OS" = "Darwin" ]; then dir="$HOME/Library/Fonts"; else dir="$HOME/.local/share/fonts"; fi
  if ls "$dir" 2>/dev/null | grep -qi "${NERD_FONT}NerdFont"; then
    ok "$NERD_FONT Nerd Font already installed"
    return
  fi
  mkdir -p "$dir"
  tmp="$(mktemp -d)"
  url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.zip"
  if curl -fsSL "$url" -o "$tmp/font.zip" && unzip -qo "$tmp/font.zip" -d "$tmp/font"; then
    find "$tmp/font" -name '*.ttf' -exec cp {} "$dir/" \;
    if have fc-cache; then fc-cache -f "$dir" >/dev/null 2>&1; fi
    ok "$NERD_FONT Nerd Font installed to $dir"
  else
    warn "Font download failed -- install $NERD_FONT Nerd Font manually"
  fi
  rm -rf "$tmp"
}
install_font

# Under WSL the terminal emulator is a Windows application, so it renders
# glyphs from Windows-installed fonts. Installing into ~/.local/share/fonts
# does nothing for it -- the font has to go onto the Windows side too.
install_font_windows() {
  local win_user win_dir ps1
  win_user="$(powershell.exe -NoProfile -Command '$env:USERNAME' 2>/dev/null | tr -d '\r')"
  if [ -z "$win_user" ]; then
    warn "Could not reach powershell.exe -- install the font on Windows manually"
    return
  fi
  win_dir="/mnt/c/Users/${win_user}/Downloads/NerdFonts"
  mkdir -p "$win_dir"
  # The plain family (ligatures, standard spacing) is the one you want in a
  # terminal; the Mono/Propo/NL files are alternate spacing variants.
  cp "$HOME/.local/share/fonts/${NERD_FONT}NerdFont-"{Regular,Bold,Italic,BoldItalic}.ttf \
     "$win_dir/" 2>/dev/null || {
    warn "Expected font files not found -- skipping the Windows install"
    return
  }

  ps1="$win_dir/install-fonts.ps1"
  # Per-user font install: copy into %LOCALAPPDATA%\Microsoft\Windows\Fonts and
  # add an HKCU registry entry. Works without administrator rights.
  cat > "$ps1" <<'PSEOF'
$src  = "$env:USERPROFILE\Downloads\NerdFonts"
$dest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$reg  = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Add-Type -AssemblyName System.Drawing
foreach ($f in Get-ChildItem "$src\*.ttf") {
  $target = Join-Path $dest $f.Name
  Copy-Item $f.FullName $target -Force
  $fc = New-Object System.Drawing.Text.PrivateFontCollection
  $fc.AddFontFile($target)
  $family = $fc.Families[0].Name
  $style  = ($f.BaseName -split "-")[-1]
  if ($style -eq "Regular") {
    $key = "$family (TrueType)"
  } else {
    # Single quotes on the replacement: in a double-quoted string PowerShell
    # would expand $1 as a variable instead of a regex backreference.
    $pretty = $style -creplace '(?<!^)([A-Z])', ' $1'
    $key = "$family $pretty (TrueType)"
  }
  New-ItemProperty -Path $reg -Name $key -PropertyType String -Value $target -Force | Out-Null
  Write-Output "  registered: $key"
}
Write-Output ""
Write-Output "  Font family name: $family"
PSEOF

  if powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$ps1")" 2>&1 | tr -d '\r'; then
    ok "Font installed on the Windows side"
  else
    warn "Windows font install failed -- open $win_dir in Explorer,"
    warn "select the .ttf files, right-click and choose Install"
  fi
}

if [ "$IS_WSL" = 1 ]; then
  step "Installing the font on the Windows side (WSL)"
  install_font_windows
  warn "Now select the font in your terminal:"
  warn "  Windows Terminal > Settings > your profile > Appearance > Font face"
  warn "  Choose 'JetBrainsMono NF'. Icons stay as boxes until you do."
fi

# --- Sync plugins and language servers --------------------------------------
step "Installing plugins (lazy.nvim)"
nvim --headless "+Lazy! sync" +qa
ok "Plugins installed"

step "Installing language servers and formatters (mason)"
# mason installs asynchronously, so this runs a script that blocks until done.
nvim --headless -c "luafile ${SCRIPT_DIR}/scripts/install-tools.lua" || warn "Some mason packages failed -- run :Mason to retry"
ok "Mason step complete"

step "Installing Treesitter parsers"
nvim --headless "+TSUpdateSync" +qa || warn "Some parsers failed to build"
ok "Parsers installed"

# --- Done -------------------------------------------------------------------
step "Done"
cat <<EOM

  Open Neovim and run:
    :checkhealth      -- verify everything is wired up
    :Lazy             -- plugin manager
    :Mason            -- language server / formatter manager

  Press <Space> and pause to see the keymap menu.

EOM
