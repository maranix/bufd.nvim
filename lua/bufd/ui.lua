local M = {}
local S = {}

local api = vim.api

---Calculates the floating window size to layout in row/col format
---
---@param height integer
---@param width integer
---
---@return integer row
---@return integer col
local function calc_window_size(height, width)
    local o = vim.o

    local row = math.floor((o.lines - height) / 2)
    local col = math.floor((o.columns - width) / 2)

    return row, col
end

---@class BufdUIState
---
---@field bufnr integer|nil The id of the bufd scratch buffer
---@field winid integer|nil The id of the window displaying bufd
local _state = {
    bufnr = nil,
    winid = nil,
}

---Checks and returns whether scratch buffer is valid
---
---@return boolean
function S.is_bufnr_valid()
    return _state.bufnr ~= nil and api.nvim_buf_is_valid(_state.bufnr)
end

---Checks and returns whether winid is valid
---
---@return boolean
function S.is_winid_valid()
    return _state.winid ~= nil and api.nvim_win_is_valid(_state.winid)
end

---@return integer|nil
function S.get_bufnr()
    return _state.bufnr
end

---@return integer|nil
function S.get_winid()
    return _state.winid
end

---@param bufnr integer
function S.set_bufnr(bufnr)
    _state.bufnr = bufnr
end

---@param winid integer
function S.set_winid(winid)
    _state.winid = winid
end

--- Creates a centered floating window and writes the provided lines into it.
---
---@param height integer
---@param width integer
---@param lines string[] The text lines to populate the buffe
function M.create_window(height, width, lines)
    if S.is_winid_valid() then
        api.nvim_set_current_win(_state.winid)
        return
    end

    local bufnr = _state.bufnr
    if not S.is_bufnr_valid() then
        bufnr = api.nvim_create_buf(false, true)
        S.set_bufnr(bufnr)
    end

    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local row, col = calc_window_size(height, width)

    --- Responsive floating window
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if S.is_winid_valid() then
                local winid = _state.winid --[[@as integer]]
                local config = api.nvim_win_get_config(winid)

                config.row, config.width = calc_window_size(config.height, config.width)

                api.nvim_win_set_config(winid, config)
            end
        end
    })

    S.set_winid(
        api.nvim_open_win(bufnr, true,
            {
                relative = "editor", -- Relative to the editor
                row = row,
                col = col,
                width = width,
                height = height,
                border = "single", -- Use a single-line border
                style = "minimal", -- Minimal UI style
                focusable = true,  -- Make it focusable
            }
        )
    )

    -- Add default keymap for closing the ui via `q`
    vim.keymap.set("n", "q", function()
        M.destroy_window()
    end, { buffer = bufnr })
end

---Destroys the created floating window
function M.destroy_window()
    if S.is_winid_valid() then
        api.nvim_win_close(_state.winid, true)
        _state.winid = nil
    end
end

M.state = S

return M
