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

local function number_global(name, fallback)
  local value = vim.g[name]
  if type(value) == 'number' and value > 0 then
    return value
  end
  return fallback
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

local function display_width(bufnr, prompt)
  local width = vim.fn.strdisplaywidth(prompt or '')
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local sample_count = clamp(number_global('fzyselect_nui_width_sample', 200), 1, line_count)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, sample_count, false)

  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  return width
end

local function buffer_prompt(bufnr)
  local ok, opts = pcall(vim.api.nvim_buf_get_var, bufnr, 'opts')
  if ok and type(opts) == 'table' and type(opts.prompt) == 'string' then
    return opts.prompt
  end
  return 'Loading...'
end

local function make_layout(bufnr, winid, stable_width)
  local max_width, max_height = available_size()
  local min_width = number_global('fzyselect_nui_min_width', 20)
  local padding = number_global('fzyselect_nui_width_padding', 2)
  local win_height = vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_height(winid) or 1
  -- Width must be monotonic while the picker is open.  fzyselect filtering can
  -- reduce the current candidate set to short lines, but shrinking nui's border
  -- window leaves stale wide border rows in the border buffer while the inner
  -- result window is reconfigured.  Grow for newly wider content, but do not
  -- shrink until this popup is closed.
  local wanted_width = math.max(stable_width or 0, display_width(bufnr, buffer_prompt(bufnr)) + padding)
  -- fzyselect.vim intentionally resizes its result window with
  -- g:fzyselect_maxheight.  Do not expand to the full buffer line count here:
  -- during command-line filtering that makes the floating content taller than
  -- fzyselect's own viewport and leaves blank/overlapped rows in the popup.
  local wanted_height = math.max(1, win_height)

  return {
    relative = 'editor',
    position = '50%',
    size = {
      width = clamp(wanted_width, math.min(min_width, max_width), max_width),
      height = clamp(wanted_height, 1, max_height),
    },
  }
end

function M.open()
  local ok_popup, Popup = pcall(require, 'nui.popup')
  local ok_autocmd, autocmd = pcall(require, 'nui.utils.autocmd')
  if not ok_popup or not ok_autocmd then
    vim.notify('fzyselect-nui-opener.nvim requires MunifTanjim/nui.nvim', vim.log.levels.ERROR)
    return
  end
  local event = autocmd.event

  local popup = Popup({
    enter = true,
    focusable = true,
    relative = 'editor',
    position = '50%',
    size = {
      width = clamp(math.floor((vim.o.columns or 80) * 0.5), 20, math.max(20, (vim.o.columns or 80) - 4)),
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
  local stable_width = nil

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

    local prompt = buffer_prompt(bufnr)
    pcall(function()
      popup.border:set_text('top', prompt, 'center')
    end)
    pcall(function()
      -- fzyselect.vim writes the prompt to the local statusline for split-window
      -- openers.  A floating window statusline is drawn on top of nui's bottom
      -- border, so clear it after fzyselect has initialized the buffer.
      vim.wo[winid].statusline = ''
    end)
    local layout = make_layout(bufnr, winid, stable_width)
    stable_width = layout.size.width
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
