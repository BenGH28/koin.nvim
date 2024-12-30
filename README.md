# koin.nvim

**K**indly **O**pen **I**n **N**eovim

Open TUI's in NeoVim with ease

# Installation
```lua
-- lazy.nvim
return {
  {
    "BenGH28/koin.nvim",
    cmd = "Koin",
    config = function()
      require "koin".setup()
    end
  },
}
```

# Usage

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
