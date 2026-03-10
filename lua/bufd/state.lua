local M = {}
local api = vim.api

---@class BufdState
---
---@field bufnr integer|nil The id of the bufd scratch buffer
---@field winid integer|nil The id of the window displaying bufd
local _state = {
    bufnr = nil,
    winid = nil,
}

--- Checks if the bufd window is currently open and valid
---@return boolean
function M.is_win_valid()
    return _state.winid ~= nil and api.nvim_win_is_valid(_state.winid)
end

--- Checks if the bufd scratch buffer exists
---@return boolean
function M.is_buf_valid()
    return _state.bufnr ~= nil and api.nvim_buf_is_valid(_state.bufnr)
end

--- Closes the bufd window if it is open and clears the state
function M.close_win()
    if M.is_win_valid() then
        api.nvim_win_close(_state.winid, true)
        _state.winid = nil
    end
end

---@return integer|nil
function M.get_bufnr()
    return _state.bufnr
end

---@return integer|nil
function M.get_winid()
    return _state.winid
end

---@param bufnr integer
function M.set_bufnr(bufnr)
    _state.bufnr = bufnr
end

---@param winid integer
function M.set_winid(winid)
    _state.winid = winid
end

return M
