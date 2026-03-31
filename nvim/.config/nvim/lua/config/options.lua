-- Basic Neovim settings for development
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = false

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

-- Enable mouse
opt.mouse = "a"

-- Better split windows
opt.splitright = true
opt.splitbelow = true

-- Swap, backup, undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
