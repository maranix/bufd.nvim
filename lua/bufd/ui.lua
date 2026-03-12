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
---@field bufnr integer? The id of the bufd scratch buffer
---@field winid integer? The id of the window displaying bufd
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

---@return integer?
function S.get_bufnr()
    return _state.bufnr
end

---@return integer?
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

---Resets winid back to nil
---
---Use this to clear the state and notify that floating window is closed
function S.reset_winid()
    _state.winid = nil
end

--- Creates a centered floating window and writes the provided lines into it.
---
---@param ui UIConfig
---@param lines string[] The text lines to populate the buffe
function M.create_window(ui, lines)
    if S.is_winid_valid() then
        local id = assert(S.get_winid(), "win_id should be valid here")
        api.nvim_set_current_win(id)
        return
    end

    local bufnr
    if not S.is_bufnr_valid() then
        bufnr = api.nvim_create_buf(false, true)
        S.set_bufnr(bufnr)

        -- Recommended UI buffer settings
        api.nvim_buf_set_name(bufnr, "Bufd")
        api.nvim_set_option_value("filetype", "bufd", { buf = bufnr })
        -- Tell Neovim we will handle the :w action
        api.nvim_set_option_value('buftype', 'acwrite', { buf = bufnr })
    else
        bufnr = assert(S.get_bufnr(), "bufnr should be valid here")
    end

    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local row, col = calc_window_size(ui.height, ui.width)

    local resize_group = api.nvim_create_augroup("BufdWindowResizer", { clear = true })
    --- Responsive floating window
    vim.api.nvim_create_autocmd("VimResized", {
        group = resize_group,
        callback = function()
            if S.is_winid_valid() then
                local id = assert(S.get_winid(), "winid should be valid here")
                local config = api.nvim_win_get_config(id)

                config.row, config.width = calc_window_size(config.height, config.width)

                api.nvim_win_set_config(id, config)
            end
        end
    })

    ---@type vim.api.keyset.win_config
    local default_opts = {
        relative = "editor", -- Relative to the editor
        row = row,
        col = col,
        style = "minimal", -- Minimal UI style
        focusable = true   -- Make it focusable
    }

    local win_conf = vim.tbl_deep_extend("force", default_opts, ui)

    S.set_winid(api.nvim_open_win(bufnr, true, win_conf))

    -- Add default keymap for closing the ui via `q`
    vim.keymap.set("n", "q", function()
        M.destroy_window()
    end, { buffer = bufnr, silent = true, nowait = true })
end

---Destroys the created floating window
function M.destroy_window()
    if S.is_winid_valid() then
        local id = assert(S.get_winid(), "winid should be valid here")
        api.nvim_win_close(id, true)
        S.reset_winid()
    end
end

M.state = S

return M
