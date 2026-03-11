local M = {}

---@class Config
---
---@field height integer Height of the floating window
---@field width integer Width of the floating window

---@type Config
local _config = {
    height = 4,
    width = 40
}

---@return Config
function M.get()
    return _config
end

---@param config Config Config table to merge
---
---@return Config _config The merged config
function M.set(config)
    _config = vim.tbl_deep_extend("force", _config, config)
    return _config
end

return M
