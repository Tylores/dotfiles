---@module 'lazy'
---@type LazySpec
return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local actions = require("diffview.actions")

    require("diffview").setup({
      enhanced_diff_hl = true, -- Use vim's native diff expressions cleanly
      use_icons = true,        -- Pulls from your web-devicons
      file_panel = {
        listing_style = "tree", -- "tree" gives you the PR folder hierarchy, "list" is flat
        tree_max_depth = 3,
        win_config = {
          position = "left",
          width = 35,
        },
      },
      keymaps = {
        -- Keymaps active inside the file tree panel
        file_panel = {
          { mode = "n", key = "j",       cb = actions.next_entry,          desc = "Bring cursor to next file" },
          { mode = "n", key = "k",       cb = actions.prev_entry,          desc = "Bring cursor to previous file" },
          { mode = "n", key = "<CR>",    cb = actions.select_entry,        desc = "Open diff for highlighted file" },
          { mode = "n", key = "s",       cb = actions.toggle_stage_entry,  desc = "Stage / Unstage selected file" },
          { mode = "n", key = "R",       cb = actions.refresh_files,       desc = "Update the file tree status" },
        },
      },
    })

    -- Global Keymaps to trigger the Review Tab
    vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open Git PR-Review Layout" })
    vim.keymap.set("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Close Git PR-Review Layout" })
  end,
}
