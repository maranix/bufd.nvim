# bufd.nvim

> Declarative buffer management for Neovim. Buffer deletion, *buffed*.

**bufd.nvim** is a minimalist Neovim plugin that treats your buffer list as an editable text file. Remove lines to mark buffers for deletion, and write (`:w`) to cleanly wipe them from your workspace.

## ✨ Features

* **Vim-Native Workflow:** Use the muscle memory you already have. `dd` to remove a buffer, `V` + `d` to remove multiple.
* **Declarative:** See exactly what is open in a temporary UI buffer, edit the list, and apply changes all at once.
* **Frictionless:** Save your changes with a standard `:w` or `:wq`.

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "maranix/bufd.nvim",
    keys = {
        { "<leader>bft", "<cmd>BufdToggle<cr>", desc = "Toggle Bufd.nvim Floating window" },
        { "<leader>bfo", "<cmd>BufdOpen<cr>",   desc = "Open Bufd.nvim Floating window" },
        { "<leader>bfc", "<cmd>BufdClose<cr>",  desc = "Close Bufd.nvim Floating window" },
    },
    opts = {}
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "maranix/bufd.nvim",
    config = function()
        require("bufd").setup()
    end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'maranix/bufd.nvim'
```

```lua
require("bufd").setup()
```

## 🚀 Usage

### Commands

| Command       | Description                                |
|---------------|--------------------------------------------|
| `:BufdOpen`   | Opens the buffer list in a floating window |
| `:BufdClose`  | Closes the floating buffer list window     |
| `:BufdToggle` | Toggles the floating buffer list window    |

### Workflow

1. Run `:BufdOpen` (or `:BufdToggle`) to open the floating buffer list.
2. Navigate the list of your currently open buffers.
3. Delete the lines of the buffers you want to close (e.g., `dd` or visual select + `d`).
4. Save the buffer (`:w`) to apply the deletions.

### Keymaps

**bufd.nvim** does not set any keymaps by default. Here is a suggested mapping:

```lua
vim.keymap.set("n", "<leader>bft", "<cmd>BufdToggle<cr>", { desc = "Toggle Bufd.nvim Floating window" })
vim.keymap.set("n", "<leader>bfo", "<cmd>BufdOpen<cr>",   { desc = "Open Bufd.nvim Floating window" })
vim.keymap.set("n", "<leader>bfc", "<cmd>BufdClose<cr>",  { desc = "Close Bufd.nvim Floating window" })
```

## ⚙️ Configuration

**bufd.nvim** comes with sensible defaults. Pass a table to `setup()` to override any option:

```lua
require("bufd").setup({
    ui = {
        height = 8,        -- Height of the floating window
        width = 80,         -- Width of the floating window
        border = "single",  -- Border style for the floating window
    },
})
```

### Options

#### `ui`

| Option   | Type                  | Default    | Description                        |
|----------|-----------------------|------------|------------------------------------|
| `height` | `integer`             | `8`        | Height of the floating window      |
| `width`  | `integer`             | `80`       | Width of the floating window       |
| `border` | `string \| string[]`  | `"single"` | Border style for the floating window. Accepts any value supported by `nvim_open_win` — `"none"`, `"single"`, `"double"`, `"rounded"`, `"solid"`, `"shadow"`, or a custom `string[]`. |

## 📄 License

This project is licensed under the [MIT License](LICENSE).
