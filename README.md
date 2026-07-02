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

## Optional globals

- `g:fzyselect_nui_min_width`: minimum content width (default: `20`).
- `g:fzyselect_nui_width_padding`: extra cells added to the measured prompt/item width (default: `2`).
- `g:fzyselect_nui_width_sample`: maximum number of candidate lines measured for width (default: `200`).

The popup height follows the current `fzyselect.vim` buffer height and is clamped to
the available editor area so the inner window stays inside the floating border.

## License

MIT License
