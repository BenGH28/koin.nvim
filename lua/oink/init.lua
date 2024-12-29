local default_opts = {
  float = true, -- false to split
  window = {
    size = 0.85,
    border = "rounded",
  },
  split = {
    direction = "left", -- left | right | above | below
    size = 0.5,
  }
}



---show a window with shell command inside of it
---@param cmd string
local show = function(cmd, opts)
  local options = vim.tbl_extend("force", default_opts, opts or {})
  local win_height = math.ceil(vim.api.nvim_win_get_height(0) * options.window.size)
  local win_width = math.ceil(vim.api.nvim_win_get_width(0) * options.window.size)

  local height = vim.api.nvim_win_get_height(0)
  local width = vim.api.nvim_win_get_width(0)
  local row = (height - win_height) / 2 - 1
  local col = (width - win_width) / 2

  local config = {}
  if options.float then
    config = {
      relative = "editor",
      row = row,
      col = col,
      width = win_width,
      height = win_height,
      border = options.window.border,
      style = "minimal",
    }
  else
    local direction = options.split.direction
    config = {
      split = direction
    }
  end

  local bufnr = vim.api.nvim_create_buf(true, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_set_current_win(win_id)
  vim.cmd("startinsert")
  vim.fn.termopen(cmd, {
    on_exit = function()
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
    on_stdout = function(id, data, name)
      if string.match("command not found", data[1]) then
        vim.notify("unknown command: " .. cmd)
      end
    end,
  })
end

M = {
  show = show,
}
function M.setup(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  vim.api.nvim_create_user_command("Oink", function(cmd_opts)
    local cmd = cmd_opts.args
    show(cmd, opts)
  end, { nargs = 1 })
end

return M
