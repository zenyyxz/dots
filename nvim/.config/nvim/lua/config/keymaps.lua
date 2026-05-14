local keymap = vim.keymap

-- Select all text
keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })
keymap.set("v", "<C-a>", "<Esc>ggVG", { desc = "Select All" })
keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Select All" })
