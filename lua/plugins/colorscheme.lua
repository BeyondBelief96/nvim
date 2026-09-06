-- gruvbox-material, carried over from the old config.
-- Swap `colorscheme` here (and in core/lazy.lua's install list) to change it.
return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000, -- load before everything else so there's no flash
    config = function()
      vim.g.gruvbox_material_background = "medium" -- soft | medium | hard
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}
