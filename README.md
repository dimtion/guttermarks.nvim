# GutterMarks.nvim

A simple Neovim plugin that displays
[marks](https://neovim.io/doc/user/motion.html#_7.-marks) in the buffer gutter
as signs. Keep track of your marks visually with customizable appearance and
behavior.

![](.github/img/screenshot_01.png)

## Features

- Display local marks (a-z) in the gutter
- Display global marks (A-Z) in the gutter
- Optional display of special marks (numbers, symbols)
- Configurable sign text and highlight groups
- Automatic refresh on text changes

### Why this pluging

I've been using [marks.nvim](https://github.com/chentoast/marks.nvim) and others
to display marks in the gutter, but I don't need all the extra bells and whistle
that those other plugins added. This is a fast, simple implementation that
doesn't get in the way, and does not change nvim default behavior.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "dimtion/guttermarks.nvim",
  event = "VeryLazy",
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'dimtion/guttermarks.nvim'
```

Then add to your `init.lua`:
```lua
require("guttermarks").setup()
```

## Configuration

See [full default configuration](lua/guttermarks/default_config.lua).

Example custom configuration:

```lua
require("guttermarks").setup({
  local_mark = {
    enabled = true,
    sign = "•",                    -- Custom sign ([default] nil uses mark letter)
    highlight_group = "DiagnosticInfo",
    priority = 10,
  },
  global_mark = {
    enabled = true,
    sign = "●",
    highlight_group = "DiagnosticWarn",
    priority = 15,
  },
  special_mark = {
    enabled = true,               -- Disabled by default
    sign = "★",
    marks = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
    highlight_group = "DiagnosticError",
    priority = 12,
  },
  -- Filetypes to exclude
  excluded_filetypes = { "help", "dashboard", "NvimTree", "neo-tree" },
  -- Customize Autocmd events that trigger refresh (not recommended)
  autocmd_triggers = { "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:GutterMarksToggle` | Toggle guttermarks display on/off |
| `:GutterMarksEnable` | Enable guttermarks display |
| `:GutterMarksDisable` | Disable guttermarks display |

## Customizing Highlights

You can customize the default highlight groups in your colorscheme or `init.lua`:

```lua
vim.api.nvim_set_hl(0, "GutterMarksLocal", { fg = "#ffff00" })
vim.api.nvim_set_hl(0, "GutterMarksGlobal", { fg = "#ff0000", bold = true })
vim.api.nvim_set_hl(0, "GutterMarksSpecial", { fg = "#00ff00", italic = true })
```

## Examples

### Enable Special Marks

```lua
require("guttermarks").setup({
  special_mark = { enabled = true },
})
```

### Minimal Setup for Local Marks Only

```lua
require("guttermarks").setup({
  global_mark = { enabled = false },
  special_mark = { enabled = false },
})
```

### Using Custom Signs

```lua
require("guttermarks").setup({
  local_mark = { sign = "▶" },
  global_mark = { sign = "▲" },
  special_mark = {
    enabled = true,
    sign = "●",
  },
})
```

## Vim Marks cheat-sheet

- Use `ma` to set local mark 'a', `mA` for global mark 'A'
- Jump to marks with `'a` (local) or `'A` (global)

## License

MIT
