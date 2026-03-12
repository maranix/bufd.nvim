local M   = {}
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
---@param curr string[] The current lines in the scratch buffer upon saving
local function close_removed_buffers(curr)
    local curr_set = {}

    for i = 1, #curr do
        local id_str = tonumber(curr[i]:match("^(%d+):"))

        if id_str then
            local b_id = assert(tonumber(id_str), "string to number conversion should not fail here")
            curr_set[b_id] = true
        end
    end

    local buffers = api.nvim_list_bufs()
    for _, b_id in ipairs(buffers) do
        if vim.fn.buflisted(b_id) == 1 and not curr_set[b_id] then
            local ok, error = pcall(vim.cmd, "bdelete " .. b_id)
            if not ok then
                vim.notify("bufd.nvim: Unsaved changes in buffer " .. b_id, vim.log.levels.WARN)
                print(vim.inspect(error))
            end
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
            local curr_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

            close_removed_buffers(curr_lines)

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
