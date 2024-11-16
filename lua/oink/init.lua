M = {}

local Oink = {}
Oink.__index = Oink

function Oink.show(opts)
  -- local height = vim.api.nvim_win_get_height(0) / 2
  -- local width = vim.api.nvim_win_get_width(0) / 2
  -- local default = { relative = 'win', row = width, col = height, width = width, height = height, border = 'single' }

  local config = { split = "left" }
  local bufnr = vim.api.nvim_create_buf(true, false)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_set_current_win(win_id)
  vim.fn.termopen(opts.args, {
    on_exit = function()
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  })
end

local function cmds()
  vim.api.nvim_create_user_command("Oink", Oink.show, { nargs = 1 })
end

function M.setup()
  cmds()
end

return M
