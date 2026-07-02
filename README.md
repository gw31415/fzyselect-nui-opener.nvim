# fzyselect-nui-opener.nvim

Use [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim) as the opener of [gw31415/fzyselect.vim](https://github.com/gw31415/fzyselect.vim).

## Dependencies

- [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [gw31415/fzyselect.vim](https://github.com/gw31415/fzyselect.vim)

## Setup

```lua
vim.g.fzyselect_opener = require('fzyselect-nui-opener')
```

For lazy-loading setups, use the opener command string directly after this plugin has
been added to `runtimepath`:

```lua
vim.g.fzyselect_opener = [[lua require('fzyselect-nui-opener.impl').open()]]
```

This avoids relying on a pre-created global Lua function when `fzyselect.vim` invokes
the opener later.

The popup width is fixed when it opens, and the height follows the current
`fzyselect.vim` buffer height while staying inside the available editor area.

## License

MIT License
