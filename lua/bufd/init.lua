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

    print(vim.inspect(lines))

    return lines
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

    ui.create_window(config.height, config.width, lines)
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
