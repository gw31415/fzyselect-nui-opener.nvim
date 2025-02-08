function _G._fzyselect_nui_opener()
	local Popup = require 'nui.popup'
	local event = require 'nui.utils.autocmd'.event
	local popup = Popup {
		enter = true,
		focusable = true,
		border = {
			style = 'rounded',
		},
		size = {
			width = 1,
			height = 1,
		},
		position = '50%',
	}
	popup:mount()
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)
end

return [[ lua _G._fzyselect_nui_opener()  ]]
