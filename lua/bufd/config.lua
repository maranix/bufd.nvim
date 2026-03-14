local M = {}

---@class UIConfig
---
---@field height integer Height of the floating window
---@field width integer Width of the floating window
---@field border? 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[]

---@class Config
---
---@field ui UIConfig

---@type Config
local _config = {
    ui = {
        height = 8,
        width = 80,
        border = "single"
    }
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
