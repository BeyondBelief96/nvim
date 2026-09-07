-- Which machine is this? Required by the handful of places that genuinely
-- have to differ between native Windows and everything else -- build commands,
-- the terminal shell, CMake output paths.
--
-- Deliberately tiny and dependency-free: it is required from plugin specs,
-- which lazy.nvim evaluates before anything else has loaded.
--
-- Note `is_windows` means *native* Windows Neovim. Under WSL Neovim is a Linux
-- binary and behaves like Linux in every way that matters here, so `is_wsl`
-- and `is_windows` are never both true.
return {
  is_windows = vim.fn.has("win32") == 1,
  is_wsl = vim.fn.has("wsl") == 1,
  is_mac = vim.fn.has("mac") == 1,
}
