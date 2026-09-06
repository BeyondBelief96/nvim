-- Headless installer for every mason package this config expects.
--
-- Run with:  nvim --headless -c 'luafile ~/.config/nvim/scripts/install-tools.lua'
--
-- Note: `-l` does NOT work here. It executes the script before the user config
-- loads, so lazy.nvim's module loader isn't installed and require("mason") fails.
--
-- mason installs asynchronously, so a plain `nvim --headless +MasonInstall +qa`
-- exits before anything finishes. This drives the registry directly and blocks
-- until every package is installed or the timeout expires.

local TIMEOUT_MS = 15 * 60 * 1000

-- mason *registry* names. These differ from the lspconfig server names used in
-- lua/plugins/lsp.lua (e.g. lspconfig `ts_ls` = mason `typescript-language-server`).
local packages = {
  -- Web
  "typescript-language-server",
  "eslint-lsp",
  "oxlint",
  "html-lsp",
  "css-lsp",
  "emmet-language-server",
  "tailwindcss-language-server",
  "json-lsp",
  "yaml-language-server",
  -- C/C++ and build
  "clangd",
  "neocmakelsp",
  -- Config
  "lua-language-server",
  -- Formatters
  "prettierd",
  "clang-format",
  "stylua",
  -- Debug adapters
  "codelldb",
  "js-debug-adapter",
}

require("mason").setup()

local registry = require("mason-registry")
local pending, failed, done = {}, {}, {}

local function log(msg)
  io.stdout:write(msg .. "\n")
  io.stdout:flush()
end

registry.refresh(function()
  for _, name in ipairs(packages) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      table.insert(failed, name .. " (not in registry)")
    elseif pkg:is_installed() then
      table.insert(done, name)
    else
      pending[name] = true
      local handle = pkg:install()
      handle:once("closed", function()
        pending[name] = nil
        if pkg:is_installed() then
          table.insert(done, name)
          log("  installed  " .. name)
        else
          table.insert(failed, name)
          log("  FAILED     " .. name)
        end
      end)
    end
  end
end)

-- Block until nothing is pending. vim.wait pumps the event loop, so the async
-- install callbacks above still run.
vim.wait(TIMEOUT_MS, function()
  return vim.tbl_isempty(pending)
end, 200)

log(("\n%d installed, %d failed"):format(#done, #failed))
if #failed > 0 then
  log("failed: " .. table.concat(failed, ", "))
end
for name, _ in pairs(pending) do
  log("timed out: " .. name)
end

vim.cmd("qa!")
