local M   = {}
local fn  = vim.fn
local api = vim.api

---@param bufs integer[] current opened buffers from neovim api
---
---@return string[]
local function get_buffer_lines(bufs)
    local lines = {}

    for _, buf in ipairs(bufs) do
        if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
            local name = api.nvim_buf_get_name(buf)
            local stat = name ~= "" and vim.loop.fs_stat(name)

            if stat and stat.type == "file" then
                name = vim.fn.fnamemodify(name, ":p:~:.")
                table.insert(lines, string.format("%d: %s", buf, name))
            end
        end
    end

    return lines
end

---Reads the UI, diffs against actual open buffers and deletes missing ones
---
---@param prev string[] Lines in the scratch buffer before saving
---@param curr string[] Lines in the scratch buffer post saving
local function close_removed_buffers(prev, curr)
    -- Build set of buffers that should remain
    local keep = {}

    for _, line in ipairs(curr) do
        local id = tonumber(line:match("^(%d+):"))
        if id then
            keep[id] = true
        end
    end

    -- Id of the buf which will be used as an alternative for the opened window
    local alt_buf = nil
    local stale_buffs = {}
    for _, line in ipairs(prev) do
        local buf = assert(tonumber(line:match("^(%d+):")), "Scratch buffer state is out of sync, Invalid line.")

        local buflisted = api.nvim_get_option_value("buflisted", { buf = buf })
        if buflisted and not keep[buf] then
            stale_buffs[buf] = true
        elseif not alt_buf then
            alt_buf = buf -- Store the id of the first common buf
        end
    end

    -- TODO: There exists a case when multiple windows are opened(Vsplit and Hsplit) and upon deletion
    -- it may switch the buffer of all visible windows to the same one alt_buf buffer upon deletion
    for buf in pairs(stale_buffs) do
        local winid = fn.bufwinid(buf)
        if winid >= 0 then
            local target_buf = alt_buf or api.nvim_get_current_buf()
            api.nvim_win_set_buf(winid, target_buf)

            if not alt_buf then
                vim.cmd("BufdClose") -- Close plugin window
            end

            api.nvim_buf_delete(buf, { force = false })
        end
    end
end

---@param cfg Config
function M.setup(cfg)
    require("bufd.config").set(cfg)

    api.nvim_create_user_command("BufdOpen", M.open_ui, { desc = "Opens the buffer list in a floating window" })
    api.nvim_create_user_command("BufdClose", M.close_ui, { desc = "Closes the floating buffer list window" })
    api.nvim_create_user_command("BufdToggle", M.toggle_ui, { desc = "Toggles the floating buffer list window" })
end

function M.open_ui()
    local ui = require("bufd.ui")
    local config = require("bufd.config").get()

    local buffers = api.nvim_list_bufs()
    local lines = get_buffer_lines(buffers)

    ui.create_window(config.ui, lines)

    local augroup = api.nvim_create_augroup("BufdManager", { clear = true })

    api.nvim_create_autocmd("BufWriteCmd", {
        desc = "Remove deleted buffer lines from scratch buffer",
        group = augroup,
        buffer = assert(ui.state.get_bufnr(), "bufnr should be valid here"),
        callback = function()
            local bufnr = assert(ui.state.get_bufnr(), "bufnr should be valid here")
            local curr = api.nvim_buf_get_lines(bufnr, 0, -1, false)

            close_removed_buffers(lines, curr)

            -- reset modified state so UI behaves like a panel
            api.nvim_set_option_value("modified", false, { buf = bufnr })
        end
    })
end

function M.close_ui()
    local ui = require("bufd.ui")
    ui.destroy_window()
end

function M.toggle_ui()
    local ui = require("bufd.ui")

    if ui.state.is_winid_valid() then
        M.close_ui()
    else
        M.open_ui()
    end
end

return M
