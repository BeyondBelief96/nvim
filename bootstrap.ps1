#Requires -Version 5.1
<#
.SYNOPSIS
  Bootstraps this Neovim config on native Windows -- no WSL involved.

.DESCRIPTION
  The Windows counterpart to bootstrap.sh. Installs the external tools the
  config shells out to, a Nerd Font, links the repo into %LOCALAPPDATA%\nvim
  if it isn't already there, then syncs plugins, language servers and
  Treesitter parsers headlessly.

  Idempotent -- safe to re-run.

.EXAMPLE
  git clone https://github.com/<you>/nvim.git $env:LOCALAPPDATA\nvim
  & $env:LOCALAPPDATA\nvim\bootstrap.ps1

.NOTES
  Run from a normal (non-elevated) PowerShell. winget may ask for elevation on
  individual packages; everything this script does itself is per-user.

  If PowerShell refuses to run it:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1
#>

[CmdletBinding()]
param(
  # Skip the package-manager step -- for when the tools already come from
  # scoop/chocolatey/a corporate image and you only want the Neovim sync.
  [switch] $SkipPackages,
  # Skip the Nerd Font install.
  [switch] $SkipFont
)

$ErrorActionPreference = 'Stop'

$NerdFont = 'JetBrainsMono'
$RepoRoot = $PSScriptRoot

# --- output helpers ---------------------------------------------------------
function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  [ok]   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [warn] $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host "  [fail] $msg" -ForegroundColor Red; exit 1 }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Installers append to the *persisted* PATH, not to this process's copy. Re-read
# it so later steps see what earlier ones installed, without a new shell.
function Update-SessionPath {
  $parts = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine')
    [Environment]::GetEnvironmentVariable('Path', 'User')
  ) | Where-Object { $_ }
  $env:Path = $parts -join ';'
}

# Several Windows installers ship a "add me to PATH" checkbox that a silent
# install leaves unticked -- LLVM and CMake both do. Put the directory on the
# user PATH ourselves when that happens.
function Add-UserPath($dir) {
  if (-not (Test-Path $dir)) { return $false }
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $already = $user -and (($user -split ';') | Where-Object { $_.TrimEnd('\') -ieq $dir.TrimEnd('\') })
  if (-not $already) {
    $joined = @($user, $dir) | Where-Object { $_ }
    [Environment]::SetEnvironmentVariable('Path', ($joined -join ';'), 'User')
  }
  Update-SessionPath
  return $true
}

# --- preflight --------------------------------------------------------------
Step 'Platform check'
if ([Environment]::GetEnvironmentVariable('WSL_DISTRO_NAME')) {
  Die 'This is a WSL shell. Run bootstrap.sh there instead.'
}
if (-not $RepoRoot) {
  Die 'Could not work out where this script lives. Run the .ps1 from disk rather than piping it in.'
}
Ok "Windows $([Environment]::OSVersion.Version) / PowerShell $($PSVersionTable.PSVersion)"

# --- packages ---------------------------------------------------------------
# The language servers and formatters themselves come from mason further down.
# What has to exist first is whatever mason and the plugins shell out to, plus
# a C compiler -- Treesitter builds every parser from source.
#
# `Fallback` is where the tool lands when the installer skips the PATH entry.
$Packages = @(
  @{ Name = 'Neovim';       Id = 'Neovim.Neovim';           Exe = 'nvim'
     Why = 'the editor'
     Fallback = @('C:\Program Files\Neovim\bin') }
  @{ Name = 'Git';          Id = 'Git.Git';                 Exe = 'git'
     Why = 'lazy.nvim, mason and fugitive all shell out to it'
     Fallback = @('C:\Program Files\Git\cmd') }
  @{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell';    Exe = 'pwsh'
     Why = 'mason requires pwsh 7+ on Windows'
     Fallback = @() }
  @{ Name = 'ripgrep';      Id = 'BurntSushi.ripgrep.MSVC'; Exe = 'rg'
     Why = 'Telescope live_grep'
     Fallback = @() }
  @{ Name = 'fd';           Id = 'sharkdp.fd';              Exe = 'fd'
     Why = 'Telescope find_files'
     Fallback = @() }
  @{ Name = 'LLVM/clang';   Id = 'LLVM.LLVM';               Exe = 'clang'
     Why = 'C compiler for Treesitter parsers, and a C/C++ toolchain'
     Fallback = @('C:\Program Files\LLVM\bin') }
  @{ Name = 'CMake';        Id = 'Kitware.CMake';           Exe = 'cmake'
     Why = 'cmake-tools, and telescope-fzf-native builds with it here'
     Fallback = @('C:\Program Files\CMake\bin') }
  @{ Name = 'Ninja';        Id = 'Ninja-build.Ninja';       Exe = 'ninja'
     Why = 'the generator cmake-tools passes to CMake'
     Fallback = @() }
  @{ Name = 'Node.js LTS';  Id = 'OpenJS.NodeJS.LTS';       Exe = 'node'
     Why = 'ts_ls, eslint, prettierd and js-debug-adapter are npm packages'
     Fallback = @('C:\Program Files\nodejs') }
)

if ($SkipPackages) {
  Warn 'Skipping package installation (-SkipPackages)'
} else {
  Step 'Installing tools'
  if (-not (Have 'winget')) {
    Die @"
winget not found. Install "App Installer" from the Microsoft Store, then
re-run. Or install these yourself and re-run with -SkipPackages:
  $(($Packages | ForEach-Object { $_.Exe }) -join ', ')
"@
  }

  foreach ($pkg in $Packages) {
    if (Have $pkg.Exe) {
      Ok "$($pkg.Name) already present"
      continue
    }
    Write-Host "  installing $($pkg.Name) -- $($pkg.Why)"
    # --silent stops vendor installers opening dialogs; the agreement flags
    # stop winget itself blocking on an interactive prompt.
    $log = & winget install --id $pkg.Id --exact --silent `
      --accept-source-agreements --accept-package-agreements `
      --disable-interactivity 2>&1
    Update-SessionPath

    if (-not (Have $pkg.Exe)) {
      foreach ($dir in $pkg.Fallback) {
        if (Add-UserPath $dir) {
          Ok "Added $dir to your user PATH"
          break
        }
      }
    }

    if (Have $pkg.Exe) {
      Ok "$($pkg.Name) installed"
    } else {
      Warn "$($pkg.Name): '$($pkg.Exe)' still not on PATH. winget said:"
      ($log | Select-Object -Last 5) | ForEach-Object { Write-Host "         $_" }
    }
  }
  Update-SessionPath
}

# Note there is no Python here, unlike bootstrap.sh. Nothing this config
# installs on Windows needs it. Add it yourself if you add a Python server.

# --- Neovim version ---------------------------------------------------------
# This config needs 0.11+ for the vim.lsp.config() API.
Step 'Checking Neovim version'
if (-not (Have 'nvim')) { Die 'nvim is not on PATH. Open a new PowerShell and re-run.' }
$versionLine = (& nvim --version | Select-Object -First 1)
if ($versionLine -match 'v(\d+)\.(\d+)') {
  $major = [int]$Matches[1]; $minor = [int]$Matches[2]
  if ($major -eq 0 -and $minor -lt 11) {
    Die "Neovim $major.$minor is too old -- need >= 0.11. Run: winget upgrade --id Neovim.Neovim"
  }
  Ok "Neovim $major.$minor"
} else {
  Warn "Could not parse version from: $versionLine"
}

# --- Nerd Font --------------------------------------------------------------
# Per-user install: copy into %LOCALAPPDATA%\Microsoft\Windows\Fonts and add an
# HKCU registry entry. No administrator rights, unlike C:\Windows\Fonts.
function Install-NerdFont {
  $dest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $reg  = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

  if (Test-Path (Join-Path $dest "${NerdFont}NerdFont-Regular.ttf")) {
    Ok "$NerdFont Nerd Font already installed"
    return
  }

  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "nerdfont-$([guid]::NewGuid())"
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $zip = Join-Path $tmp 'font.zip'
  $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NerdFont}.zip"

  # Without this, Invoke-WebRequest on Windows PowerShell 5.1 redraws a
  # progress bar per chunk and takes minutes on a fast connection.
  $oldProgress = $ProgressPreference
  $ProgressPreference = 'SilentlyContinue'
  try {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'font') -Force
  } catch {
    Warn "Font download failed ($($_.Exception.Message)) -- install $NerdFont Nerd Font by hand"
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    return
  } finally {
    $ProgressPreference = $oldProgress
  }

  # The plain family (ligatures, standard spacing) is the one you want in a
  # terminal; the Mono/Propo/NL files are alternate spacing variants.
  $wanted = @('Regular', 'Bold', 'Italic', 'BoldItalic') |
    ForEach-Object { "${NerdFont}NerdFont-$_.ttf" }
  $files = @(Get-ChildItem -Path (Join-Path $tmp 'font') -Recurse -Filter '*.ttf' |
    Where-Object { $wanted -contains $_.Name })

  if ($files.Count -eq 0) {
    Warn "No matching .ttf files in the archive -- install $NerdFont Nerd Font by hand"
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    return
  }

  # Reading the real family name out of the font file is what makes the
  # registry entry match what the font picker shows. If System.Drawing isn't
  # loadable, fall back to the name Nerd Fonts uses by convention.
  $canReadFamily = $true
  try { Add-Type -AssemblyName System.Drawing } catch { $canReadFamily = $false }

  $family = "$NerdFont NF"
  foreach ($f in $files) {
    $target = Join-Path $dest $f.Name
    Copy-Item $f.FullName $target -Force
    if ($canReadFamily) {
      try {
        $fc = New-Object System.Drawing.Text.PrivateFontCollection
        $fc.AddFontFile($target)
        $family = $fc.Families[0].Name
      } catch { $canReadFamily = $false }
    }
    $style = ($f.BaseName -split '-')[-1]
    if ($style -eq 'Regular') {
      $key = "$family (TrueType)"
    } else {
      # Single quotes on the replacement: in a double-quoted string PowerShell
      # would expand $1 as a variable instead of a regex backreference.
      $pretty = $style -creplace '(?<!^)([A-Z])', ' $1'
      $key = "$family $pretty (TrueType)"
    }
    New-ItemProperty -Path $reg -Name $key -PropertyType String -Value $target -Force | Out-Null
  }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Ok "$NerdFont Nerd Font installed -- family name: $family"
}

if ($SkipFont) {
  Warn 'Skipping font install (-SkipFont)'
} else {
  Step "Installing $NerdFont Nerd Font"
  Install-NerdFont
}

# --- config location --------------------------------------------------------
# Windows Neovim reads %LOCALAPPDATA%\nvim, not ~/.config/nvim. If the repo is
# checked out elsewhere, junction it into place: junctions need neither
# elevation nor Developer Mode, unlike symlinks.
Step 'Config location'
$target = Join-Path $env:LOCALAPPDATA 'nvim'
if ($RepoRoot.TrimEnd('\') -ieq $target.TrimEnd('\')) {
  Ok "Repo is already at $target"
} elseif (Test-Path $target) {
  $isLink = ((Get-Item $target -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
  if ($isLink) {
    Ok "$target is already a link -- leaving it alone"
  } else {
    # Stopping here on purpose: the sync steps below would otherwise install
    # plugins and servers for whatever config is sitting in that directory.
    Die @"
$target already exists as a real directory, so Neovim loads that, not this
repo ($RepoRoot). Move it aside and re-run, or clone directly into $target.
"@
  }
} else {
  New-Item -ItemType Junction -Path $target -Target $RepoRoot | Out-Null
  Ok "Linked $target -> $RepoRoot"
}

# --- sync plugins and tooling ----------------------------------------------
Step 'Installing plugins (lazy.nvim)'
& nvim --headless '+Lazy! sync' +qa
Ok 'Plugins installed'

Step 'Installing language servers and formatters (mason)'
# mason installs asynchronously, so this runs a script that blocks until done.
# Forward slashes and escaped spaces: :luafile takes a Vim-style path.
$installer = (Join-Path $RepoRoot 'scripts\install-tools.lua') -replace '\\', '/' -replace ' ', '\ '
& nvim --headless -c "luafile $installer"
if ($LASTEXITCODE -ne 0) { Warn 'Some mason packages failed -- run :Mason to retry' }
Ok 'Mason step complete'

Step 'Installing Treesitter parsers'
& nvim --headless '+TSUpdateSync' +qa
if ($LASTEXITCODE -ne 0) { Warn "Some parsers failed to build -- check that 'clang' is on PATH" }
Ok 'Parsers installed'

# --- done -------------------------------------------------------------------
Step 'Done'
@"

  Set your terminal font, or the icons render as boxes:
    Windows Terminal > Settings > your profile > Appearance > Font face
    Choose 'JetBrainsMono NF'.

  Open a NEW terminal (so it picks up the PATH changes), then run nvim and:
    :checkhealth      -- verify everything is wired up
    :Lazy             -- plugin manager
    :Mason            -- language server / formatter manager

  Press <Space> and pause to see the keymap menu.

"@ | Write-Host
