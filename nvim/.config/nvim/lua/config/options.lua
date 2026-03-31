-- Basic Neovim settings for development
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true

-- Clipboard (system clipboard)
opt.clipboard = "unnamedplus"

-- Disable mouse
opt.mouse = ""

-- Better split windows
opt.splitright = true
opt.splitbelow = true

-- Swap, backup, undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
