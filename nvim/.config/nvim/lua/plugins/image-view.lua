return {
  {
    '3rd/image.nvim',
    opts = {
      backend = 'sixel', -- Tells Neovim to translate pixels into Sixel streams for Windows Terminal
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width = 100,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_ft = { 'help', 'lazy', 'telescope' },
    },
  },
}
