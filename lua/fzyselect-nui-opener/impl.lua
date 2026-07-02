local M = {}

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if value > max_value then
    return max_value
  end
  return value
end

local function available_size()
  local columns = math.max(1, vim.o.columns or 1)
  local lines = math.max(1, vim.o.lines or 1)
  local cmdheight = vim.o.cmdheight or 1

  -- Leave room for the border and for Neovim's command/status area.  A small
  -- margin is intentional: the fzyselect buffer can resize synchronously while
  -- nui redraws its border asynchronously, and exact edge placement is prone to
  -- off-by-one clipping on small terminals.
  return math.max(1, columns - 4), math.max(1, lines - cmdheight - 4)
end

local function buffer_prompt(bufnr)
  local ok, opts = pcall(vim.api.nvim_buf_get_var, bufnr, 'opts')
  if ok and type(opts) == 'table' and type(opts.prompt) == 'string' then
    return opts.prompt
  end
  return 'Loading...'
end

local function make_layout(winid, stable_width)
  local max_width, max_height = available_size()
  local win_height = vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_height(winid) or 1
  -- fzyselect.vim intentionally resizes its result window with
  -- g:fzyselect_maxheight.  Do not expand to the full buffer line count here:
  -- during command-line filtering that makes the floating content taller than
  -- fzyselect's own viewport and leaves blank/overlapped rows in the popup.
  local wanted_height = math.max(1, win_height)

  return {
    relative = 'editor',
    position = '50%',
    size = {
      width = clamp(stable_width or 0, 20, max_width),
      height = clamp(wanted_height, 1, max_height),
    },
  }
end

local function initial_width()
  local columns = vim.o.columns or 80
  return clamp(math.floor(columns * 0.5), 20, math.max(20, columns - 4))
end

function M.open()
  local ok_popup, Popup = pcall(require, 'nui.popup')
  local ok_autocmd, autocmd = pcall(require, 'nui.utils.autocmd')
  if not ok_popup or not ok_autocmd then
    vim.notify('fzyselect-nui-opener.nvim requires MunifTanjim/nui.nvim', vim.log.levels.ERROR)
    return
  end
  local event = autocmd.event
  local width = initial_width()

  local popup = Popup({
    enter = true,
    focusable = true,
    relative = 'editor',
    position = '50%',
    size = {
      width = width,
      height = 1,
    },
    border = {
      style = 'rounded',
      text = {
        top = 'Loading...',
        top_align = 'center',
      },
    },
    buf_options = {
      buflisted = false,
      swapfile = false,
    },
  })

  popup:mount()

  local bufnr = popup.bufnr
  local winid = popup.winid
  local closed = false
  local pending = false
  local stable_width = width

  local function close()
    if closed then
      return
    end
    closed = true
    if popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
      pcall(function()
        popup:unmount()
      end)
    end
  end

  local function refresh()
    pending = false
    if closed or not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
      close()
      return
    end

    pcall(function()
      popup.border:set_text('top', buffer_prompt(bufnr), 'center')
    end)
    pcall(function()
      -- fzyselect.vim writes the prompt to the local statusline for split-window
      -- openers.  A floating window statusline is drawn on top of nui's bottom
      -- border, so clear it after fzyselect has initialized the buffer.
      vim.wo[winid].statusline = ''
    end)
    local layout = make_layout(winid, stable_width)
    pcall(function()
      popup:update_layout(layout)
    end)
  end

  local function schedule_refresh()
    if closed or pending then
      return
    end
    pending = true
    vim.schedule(refresh)
  end

  schedule_refresh()

  local group = vim.api.nvim_create_augroup('fzyselect_nui_opener_' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    buffer = bufnr,
    callback = schedule_refresh,
  })
  vim.api.nvim_create_autocmd({ 'WinScrolled', 'VimResized' }, {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_buf() == bufnr then
        schedule_refresh()
      end
    end,
  })

  popup:on(event.BufLeave, close, { once = true })
  popup:on(event.WinClosed, close, { once = true })
end

return M
