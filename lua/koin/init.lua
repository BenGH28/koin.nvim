local M = {}
local History = {}

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

-- defaults merged with whatever was passed to setup()
local configured_opts = default_opts

-- exit code bash uses when the command can't be found, cmd has no equivalent and just exits with 1
local COMMAND_NOT_FOUND = 127

---scale a dimension by a 0 to 1 ratio, keeping it large enough to open a window
---@param total integer
---@param ratio number
---@return integer
local function scale(total, ratio)
  return math.max(1, math.floor(total * ratio))
end

---move cmd to the front of the history, so History[1] is always the last command run
---@param cmd string
local function remember(cmd)
  for i = #History, 1, -1 do
    if History[i] == cmd then
      table.remove(History, i)
    end
  end
  table.insert(History, 1, cmd)
end

---show a window with shell command inside of it
---@param cmd string
---@param opts? table options to configure display of TUI's, defaults to the options given to setup
M.show = function(cmd, opts)
  remember(cmd)

  local options = vim.tbl_deep_extend("force", configured_opts, opts or {})

  local config = {}
  if options.float then
    local height = vim.o.lines - vim.o.cmdheight
    local width = vim.o.columns
    local win_height = scale(height, options.window.size)
    local win_width = scale(width, options.window.size)
    config = {
      relative = "editor",
      row = math.max(0, math.floor((height - win_height) / 2) - 1),
      col = math.floor((width - win_width) / 2),
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
    if direction == "left" or direction == "right" then
      config.width = scale(vim.api.nvim_win_get_width(0), options.split.size)
    else
      config.height = scale(vim.api.nvim_win_get_height(0), options.split.size)
    end
  end

  local bufnr = vim.api.nvim_create_buf(true, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_set_current_win(win_id)
  vim.cmd("startinsert")

  local cmd_list = {}
  if vim.fn.has("win32") == 1 then
    cmd_list = { "cmd", "/c", cmd }
  else
    cmd_list = { "bash", "-c", cmd }
  end
  local job_opts = {
    on_exit = function(job, exit_code, event)
      if exit_code == COMMAND_NOT_FOUND then
        vim.notify("Unknown command: " .. cmd, vim.log.levels.ERROR)
      elseif exit_code ~= 0 then
        vim.notify(("Command `%s` exited with code %d"):format(cmd, exit_code), vim.log.levels.ERROR)
      end
      -- the window or buffer may already be gone if the user closed it while the job was running
      if vim.api.nvim_win_is_valid(win_id)
          and #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win_id)) > 1 then
        vim.api.nvim_win_close(win_id, true)
      end
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end,
  }
  if vim.fn.has("nvim-0.11") == 1 then
    job_opts.term = true
    vim.fn.jobstart(cmd_list, job_opts)
  else
    vim.fn.termopen(cmd_list, job_opts)
  end
end


local koin_last = function(cmd)
  if cmd ~= "" then
    M.show(cmd)
  elseif History and #History > 0 then
    M.show(History[1])
  else
    vim.notify("koin last command is nil")
  end
end


---complete :KoinLast from the history, matching everything typed so far
---@param arg_lead string the word being completed
---@param cmd_line string
---@param cursor_pos integer
---@return string[]
local function complete_history(arg_lead, cmd_line, cursor_pos)
  local typed = cmd_line:sub(1, cursor_pos):match("^%s*%S+%s+(.*)$") or ""
  local matches = {}
  for _, entry in ipairs(History) do
    if vim.startswith(entry, typed) then
      -- neovim only replaces the current word, so leave out any earlier words already typed
      table.insert(matches, entry:sub(#typed - #arg_lead + 1))
    end
  end
  return matches
end


function M.setup(opts)
  configured_opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  vim.api.nvim_create_user_command("Koin", function(cmd_opts)
    M.show(cmd_opts.args)
  end, {
    nargs = '+',
    complete = "shellcmd"
  })

  vim.api.nvim_create_user_command("KoinClear", function()
    History = {}
    vim.notify("Koin history cleared")
  end, {})

  vim.api.nvim_create_user_command("KoinLast", function(cmd_opts)
    koin_last(cmd_opts.args)
  end, {
    nargs = '*',
    complete = complete_history,
  })
end

return M
