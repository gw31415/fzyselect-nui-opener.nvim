function _G._fzyselect_nui_opener()
	local Popup = require 'nui.popup'
	local event = require 'nui.utils.autocmd'.event
	local popup = Popup {
		enter = true,
		focusable = true,
		border = {
			style = 'rounded',
			text = {
				top = 'Loading....',
				top_align = 'center',
			}
		},
		size = {
			width = '50%',
			height = 1,
		},
		position = '50%',
	}
	popup:mount()
	vim.api.nvim_create_autocmd('TextChanged', {
		buffer = 0,
		callback = function()
			popup.border:set_text('top', vim.b.opts.prompt, 'center')
			popup:update_layout {
				size = {
					height = vim.api.nvim_win_get_height(0),
					width = vim.api.nvim_win_get_width(0),
				},
				position = '50%',
			}
		end,
	})
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)
end

return [[ lua _G._fzyselect_nui_opener()  ]]
