local Oink = {}
Oink.__index = Oink

local default_opts = {
  float = true,             -- false to split
  split_direction = "left", -- left | right | above | below
  float_size = 0.85,
  split_size = 0.5,
}

function Oink:new(opts)
  local instance = setmetatable({}, Oink)
  opts = vim.tbl_extend("force", default_opts, opts)
  instance.opts = opts
  return instance
end

function Oink:dbg_opts()
  print(vim.inspect(self.opts))
end

function Oink:show(args)
  local win_height = math.ceil(vim.api.nvim_win_get_height(0) * self.opts.float_size)
  local win_width = math.ceil(vim.api.nvim_win_get_width(0) * self.opts.float_size)

  local height = vim.api.nvim_win_get_height(0)
  local width = vim.api.nvim_win_get_width(0)
  local row = (height - win_height) / 2 - 1
  local col = (width - win_width) / 2

  local config = {}
  if self.opts.float then
    config = {
      relative = "editor",
      row = row,
      col = col,
      width = win_width,
      height = win_height,
      border = "rounded",
      style = "minimal"
    }
  else
    config = { split = self.opts.split_direction }
  end

  local bufnr = vim.api.nvim_create_buf(true, false)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_set_current_win(win_id)
  vim.cmd("startinsert")
  vim.fn.termopen(args.args, {
    on_exit = function()
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  })
end

local function cmds(oink)
  vim.api.nvim_create_user_command("Oink", function(opts)
    oink:show(opts)
  end, { nargs = 1 })
end


M = {}

function M.setup(opts)
  opts = opts or {}
  local oink = Oink:new(opts)
  cmds(oink)
end

return M
