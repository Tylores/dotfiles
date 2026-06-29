-- Add indentation guides even on blank lines
-- See `:help ibl`

---@module 'lazy'
---@type LazySpec
return {
  {
    'lukas-reineke/indent-blankline.nvim',
    enabled = false, -- Enable this by changing to true
    main = 'ibl',
    ---@module 'ibl'
    ---@type ibl.config
    opts = {},
  },
}
