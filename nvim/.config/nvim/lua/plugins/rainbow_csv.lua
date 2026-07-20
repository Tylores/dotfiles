return {
  {
    'mechatroner/rainbow_csv',
    ft = { 'csv', 'tsv' },
    keys = {
      {
        '<leader>vd',
        function()
          local file = vim.api.nvim_buf_get_name(0)
          if file == '' then
            vim.notify('Current buffer has no file path', vim.log.levels.WARN)
            return
          end
          vim.cmd 'vsplit'
          vim.cmd('terminal vd ' .. vim.fn.shellescape(file))
          vim.cmd 'startinsert'
        end,
        desc = 'Open CSV in VisiData split',
      },
    },
  },
}
