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


M = {
  history = {},
}


---show a window with shell command inside of it
---@param cmd string
---@param opts? table options to configure display of TUI's
local show = function(cmd, opts)
  if not vim.tbl_contains(M.history, cmd) then
    table.insert(M.history, 1, cmd)
  end

  local options = vim.tbl_extend("force", default_opts, opts or {})
  local win_height = math.floor(vim.api.nvim_win_get_height(0) * options.window.size)
  local win_width = math.floor(vim.api.nvim_win_get_width(0) * options.window.size)

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
    on_exit = function(job, exit_code, event)
      if exit_code ~= 0 then
        vim.notify("Unknown command: " .. cmd, vim.log.levels.ERROR)
      end
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
  })
end

local koin = function(cmd, opts)
  show(cmd, opts)
end

local koin_last = function(cmd, opts)
  if cmd ~= "" then
    show(cmd, opts)
  elseif M.history and #M.history > 0 then
    cmd = M.history[1]
    show(M.history[1], opts)
  else
    vim.notify("koin last command is nil")
  end
end

M.show = show

function M.setup(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  vim.api.nvim_create_user_command("Koin", function(cmd_opts)
    koin(cmd_opts.args, opts)
  end, {
    nargs = '+',
    complete = "shellcmd"
  })

  vim.api.nvim_create_user_command("KoinClear", function()
    M.history = {}
    vim.notify("Koin history cleared")
  end, {})

  vim.api.nvim_create_user_command("KoinLast", function(cmd_opts)
    koin_last(cmd_opts.args, opts)
  end, {
    nargs = '*',
    complete = function()
      return M.history
    end
  })
end

return M
