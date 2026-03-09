# bufd.nvim

> Declarative buffer management for Neovim. Buffer deletion, *buffed*.

**bufd.nvim** is a minimalist Neovim plugin that treats your buffer list as an editable text file. Remove lines to mark buffers for deletion, and write (`:w`) to cleanly wipe them from your workspace.

## ✨ Features

* **Vim-Native Workflow:** Use the muscle memory you already have. `dd` to remove a buffer, `V` + `d` to remove multiple.
* **Declarative:** See exactly what is open in a temporary UI buffer, edit the list, and apply changes all at once.
* **Frictionless:** Save your changes with a standard `:w`.

## 📦 Installation

*(Installation instructions coming soon. Compatible with lazy.nvim, packer, etc.)*

## 🚀 Usage

1. Open the `bufd` interface.
2. Navigate the list of your currently open buffers.
3. Delete the lines of the buffers you want to close (e.g., using `dd`).
4. Save the buffer (`:w`) to apply the deletions. 
