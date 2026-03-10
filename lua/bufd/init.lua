local M = {}
local api = vim.api

local state = require("bufd.state")

---@param bufs integer[] current opened buffers from neovim api
---@param bufnr integer id of bufd.nvim scratch buffer
---
---@return string[]
local function get_buffer_lines(bufs, bufnr)
    local lines = {}
    local map = {}

    for _, buf in ipairs(bufs) do
        if vim.bo[buf].buflisted then
            local name = api.nvim_buf_get_name(buf)

            if name == "" then
                name = "[No Name]"
            else
                name = vim.fn.fnamemodify(name, ":p:~:.")
            end

            table.insert(lines, name)
            table.insert(map, buf)
        end
    end

    vim.b[bufnr].bufd_bufs = map

    return lines
end

local function on_write()
    if not state.is_buf_valid() then
        return
    end

    local bufnr = state.get_bufnr() --[[@as integer]]

    ---@type integer[]
    local map = vim.b[bufnr].bufd_bufs
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local kept = {}

    for i = 1, #lines do
        local buf = map[i]
        if buf then
            kept[buf] = true
        end
    end

    local buffers = api.nvim_list_bufs()
    local deleted = 0

    for _, buf in ipairs(buffers) do
        if vim.bo[buf].buflisted and not kept[buf] then
            api.nvim_buf_delete(buf, { force = false })
            deleted = deleted + 1
        end
    end

    api.nvim_set_option_value('modified', false, { buf = bufnr })

    local new_lines = get_buffer_lines(api.nvim_list_bufs(), bufnr)
    api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

    -- Only notify if we actually did something, keeps things quiet and pro
    if deleted > 0 then
        vim.notify(string.format("Bufd: Deleted %d buffer(s).", deleted), vim.log.levels.INFO)
    end
end

function M.setup()
    api.nvim_create_user_command("BufdToggle", M.toggle_ui, {})
end

function M.toggle_ui()
    if state.is_win_valid() then
        state.close_win()
        return
    end

    if not state.is_buf_valid() then
        local bufnr = api.nvim_create_buf(false, true)
        state.set_bufnr(bufnr)

        api.nvim_buf_set_name(bufnr, "Bufd")
        api.nvim_set_option_value("filetype", "bufd", { buf = bufnr })

        -- Recommended UI buffer settings
        -- Hide this buffer from appearing in buf list
        api.nvim_set_option_value("buflisted", false, { buf = bufnr })
        api.nvim_set_option_value("swapfile", false, { buf = bufnr })
        api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

        -- Tell Neovim we will handle the :w action
        api.nvim_set_option_value('buftype', 'acwrite', { buf = bufnr })

        -- Create an Autocommand group to prevent duplicate hooks
        local augroup = api.nvim_create_augroup("BufdManager", { clear = true })

        -- Intercept the write command
        api.nvim_create_autocmd("BufWriteCmd", {
            group = augroup,
            buffer = bufnr,
            callback = on_write,
            desc = "Apply bufd write action on save (Closes deleted buffers)",
        })


        -- Add default keymap for closing the ui via `q`
        vim.keymap.set("n", "q", function()
            state.close_win()
        end, { buffer = bufnr })
    end

    local bufnr = state.get_bufnr()
    if bufnr == nil then
        error("Bufd: expected bufnr to be not nil", 0)
        return
    end

    local buffers = api.nvim_list_bufs()
    local buf_lines = get_buffer_lines(buffers, bufnr)

    if #buf_lines ~= 0 then
        api.nvim_buf_set_lines(bufnr, 0, -1, false, buf_lines)
        api.nvim_set_option_value('modified', false, { buf = bufnr })
    end

    vim.cmd("botright vsplit")
    local winid = api.nvim_get_current_win()

    state.set_winid(winid)
    api.nvim_win_set_buf(winid, bufnr)
end

return M
