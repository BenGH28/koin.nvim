-- Run from anywhere with:
--   nvim --headless -u NONE -i NONE -l tests/koin_test.lua
-- Exits non-zero if any test fails. Output from the commands under test is mixed in with the results.

local script = debug.getinfo(1, "S").source:sub(2)
vim.opt.rtp:prepend(vim.fn.fnamemodify(script, ":p:h:h"))

-- floats are sized from these. headless windows don't resize with them, so tests of
-- window-relative sizes read the real window size instead of assuming 120x40
vim.o.columns, vim.o.lines = 120, 40

local is_windows = vim.fn.has("win32") == 1

-- stays alive for about a second, so a test can inspect the window while the job runs
local SLOW = is_windows and "ping -n 2 127.0.0.1 >nul" or "sleep 1"

local notes = {}
vim.notify = function(msg) table.insert(notes, msg) end

local function fresh()
  package.loaded["koin"] = nil
  vim.cmd("silent! only!")
  vim.v.errmsg = ""
  notes = {}
  return require("koin")
end

-- wait for every terminal buffer to go, which happens once their jobs have exited
local function settle()
  vim.wait(3000, function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buftype == "terminal" then return false end
    end
    return true
  end, 20)
  vim.wait(50)
end

local failures, total = 0, 0

local function check(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if not ok then failures = failures + 1 end
  print((ok and "PASS " or "FAIL ") .. name .. (ok and "" or ("\n     " .. tostring(err):gsub("\n", " "))))
  pcall(settle)
end

local function eq(actual, expected, what)
  if not vim.deep_equal(actual, expected) then
    error(what .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual), 0)
  end
end

check("partial window opts in setup do not crash, border applied", function()
  local k = fresh()
  k.setup({ window = { border = "single" } })
  vim.cmd("Koin " .. SLOW)
  local c = vim.api.nvim_win_get_config(0)
  eq(c.relative, "editor", "relative")
  eq(c.width, 102, "width") -- 120 * default 0.85
end)

check("partial opts passed straight to show do not crash", function()
  local k = fresh()
  k.show(SLOW, { window = { size = 0.5 } })
  eq(vim.api.nvim_win_get_config(0).width, 60, "width")
end)

check("split.size applied, left/right uses width", function()
  local k = fresh()
  local w = vim.api.nvim_win_get_width(0)
  k.setup({ float = false, split = { direction = "right", size = 0.25 } })
  vim.cmd("Koin " .. SLOW)
  eq(vim.api.nvim_win_get_width(0), math.floor(w * 0.25), "width")
end)

check("split.size applied, above/below uses height", function()
  local k = fresh()
  local h = vim.api.nvim_win_get_height(0)
  k.setup({ float = false, split = { direction = "below", size = 0.25 } })
  vim.cmd("Koin " .. SLOW)
  eq(vim.api.nvim_win_get_height(0), math.floor(h * 0.25), "height")
end)

check("float sized from the editor when inside a split", function()
  local k = fresh()
  k.setup({ window = { size = 0.5 } })
  vim.cmd("vsplit | vsplit")
  vim.cmd("Koin " .. SLOW)
  local c = vim.api.nvim_win_get_config(0)
  eq(c.width, 60, "width")
  eq(c.col, 30, "col")
end)

check("show without opts uses setup options", function()
  local k = fresh()
  k.setup({ window = { size = 0.5 } })
  k.show(SLOW)
  eq(vim.api.nvim_win_get_config(0).width, 60, "width")
end)

check("repeated command moves to front of history", function()
  local k = fresh()
  k.setup()
  for _, c in ipairs({ "echo A", "echo B", "echo A" }) do
    vim.cmd("Koin " .. c)
    settle()
  end
  eq(vim.fn.getcompletion("KoinLast ", "cmdline"), { "echo A", "echo B" }, "history")
end)

check("completion filters on what has been typed", function()
  local k = fresh()
  k.setup()
  for _, c in ipairs({ "exit 0", "echo one", "echo two" }) do
    vim.cmd("Koin " .. c)
    settle()
  end
  eq(vim.fn.getcompletion("KoinLast ec", "cmdline"), { "echo two", "echo one" }, "first word")
  eq(vim.fn.getcompletion("KoinLast echo t", "cmdline"), { "two" }, "second word")
  eq(vim.fn.getcompletion("KoinLast zzz", "cmdline"), {}, "no match")
end)

check("non-zero exit reports the code, not unknown command", function()
  local k = fresh()
  k.setup()
  vim.cmd("Koin exit 3")
  settle()
  eq(notes, { "Command `exit 3` exited with code 3" }, "notes")
end)

check("exit code 127 reports unknown command", function()
  local k = fresh()
  k.setup()
  vim.cmd("Koin exit 127")
  settle()
  eq(notes, { "Unknown command: exit 127" }, "notes")
end)

check("missing command is reported", function()
  local k = fresh()
  k.setup()
  vim.cmd("Koin koin_no_such_command_xyz")
  settle()
  -- cmd exits with 1 for a missing command, bash with 127
  local expected = is_windows
      and "Command `koin_no_such_command_xyz` exited with code 1"
      or "Unknown command: koin_no_such_command_xyz"
  eq(notes, { expected }, "notes")
end)

check("clean exit is silent and closes the window", function()
  local k = fresh()
  k.setup()
  local before = #vim.api.nvim_list_wins()
  vim.cmd("Koin exit 0")
  settle()
  eq(notes, {}, "notes")
  eq(#vim.api.nvim_list_wins(), before, "windows")
end)

check("closing the window before the job ends raises no error", function()
  local k = fresh()
  k.setup()
  vim.cmd("Koin " .. SLOW)
  vim.api.nvim_win_close(0, true)
  settle()
  eq(vim.v.errmsg, "", "errmsg")
  local terminals = vim.tbl_filter(function(b)
    return vim.bo[b].buftype == "terminal"
  end, vim.api.nvim_list_bufs())
  eq(#terminals, 0, "terminal buffers")
end)

check("only remaining window at exit raises no error", function()
  local k = fresh()
  k.setup({ float = false })
  vim.cmd("Koin " .. SLOW)
  vim.cmd("only")
  settle()
  eq(vim.v.errmsg, "", "errmsg")
  eq(#vim.api.nvim_list_wins(), 1, "windows")
end)

print(("\n%d/%d passed"):format(total - failures, total))
os.exit(failures == 0 and 0 or 1)
