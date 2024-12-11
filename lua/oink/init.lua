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

--- @class Oink
--- @field new fun(self: Oink, opts: table): Oink
--- @field show fun(self: Oink, cmd: string)
--- @field opts table
local Oink = {}

---constructor
---@param opts table
---@return Oink
function Oink:new(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  local obj = { opts = opts }
  obj = setmetatable(obj, { __index = self })
  return obj
end

---show a window with shell command inside of it
---@param cmd string
function Oink:show(cmd)
  local win_height = math.ceil(vim.api.nvim_win_get_height(0) * self.opts.window.size)
  local win_width = math.ceil(vim.api.nvim_win_get_width(0) * self.opts.window.size)

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
      border = self.opts.window.border,
      style = "minimal",
    }
  else
    local direction = self.opts.split.direction
    config = {
      split = direction
    }
  end

  local bufnr = vim.api.nvim_create_buf(true, false)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_set_current_win(win_id)
  vim.cmd("startinsert")
  vim.fn.termopen(cmd, {
    on_exit = function()
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  })
end

--- Create the user commands for Oink.nvim
--- @param oink Oink
local function cmds(oink)
  vim.api.nvim_create_user_command("Oink", function(opts)
    local cmd = opts.args
    oink:show(cmd)
  end, { nargs = 1 })
end


M = {}

function M.setup(opts)
  opts = opts or {}
  local oink = Oink:new(opts)
  cmds(oink)
end

return M
