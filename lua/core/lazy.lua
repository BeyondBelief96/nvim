-- Bootstrap lazy.nvim (the plugin manager) if it isn't present yet.
-- This is what makes the repo self-installing: clone the config, launch nvim,
-- and lazy.nvim fetches itself and then every plugin.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Import every file in lua/plugins/ as a plugin spec.
  spec = { { import = "plugins" } },

  install = { colorscheme = { "gruvbox-material", "habamax" } },
  checker = { enabled = true, notify = false }, -- check for updates, quietly
  change_detection = { notify = false },

  ui = { border = "rounded" },

  -- No plugin here needs luarocks, so don't let lazy.nvim install its private
  -- Lua 5.1 + luarocks toolchain (hererocks) just to satisfy the check. Without
  -- this, :checkhealth reports a missing luarocks that nothing actually wants.
  rocks = { hererocks = false, enabled = false },

  performance = {
    rtp = {
      -- Disable built-in plugins we replace or don't use. Shaves startup time.
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
