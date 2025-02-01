<div align="center">
    <img src="https://github.com/user-attachments/assets/88ed87be-fbc1-4405-9f73-8378635694b2" alt="a gold coin" style="width:150px;height:auto;"/>
</div>
<div align=center>
    <h1>koin.nvim</h1>
    <h3>Kindly Open In Neovim</h3>
</div>




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

## API

Use the `show` function to script your own solutions

```lua
opts = {
    -- your config here or default_opts
}
cmd = "htop"
require("koin").show(cmd, opts)
```
