# koin.nvim

**K**indly **O**pen **I**n **N**eovim

Open TUI's in NeoVim with ease

## Installation
```lua
-- lazy.nvim
return {
  {
    "BenGH28/koin.nvim",
    cmd = {"Koin", "KoinLast", "KoinClear"},
    config = function()
      require "koin".setup()
    end
  },
}
```


## Usage

Run a tui application inside of a neovim window
```vim
:Koin lazygit
:Koin lazydocker
:Koin <your tui application here>
```

Look through your Koin history and run that
```vim
:KoinLast 'to execute last command
:KoinLast <tab> 'press tab to cycle through koin history
```

Clear you history with `:KoinClear`


## Configure

```lua
local default_opts = {
  float = true, -- false to split
  window = {
    size = 0.85, -- 0 to 1
    border = "rounded", -- none| single| double| rounded| solid| shadow
  },
  split = {
    direction = "left", -- left | right | above | below
    size = 0.5, -- 0 to 1
  }
}

require("koin").setup(default_opts)
```
