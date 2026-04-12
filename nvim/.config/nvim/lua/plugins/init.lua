return {
  -- Color scheme (Catppuccin to match your rice)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        integrations = {
          alpha = true,
          cmp = true,
          gitsigns = true,
          indent_blankline = { enabled = true },
          lualine = true,
          mason = true,
          noice = true,
          notify = true,
          nvimtree = true,
          telescope = { enabled = true },
          which_key = true,
        },
        custom_highlights = function(colors)
          return {
            -- Force transparency across various UI components
            LualineNormal = { bg = "NONE" },
            LualineInsert = { bg = "NONE" },
            LualineVisual = { bg = "NONE" },
            LualineReplace = { bg = "NONE" },
            LualineCommand = { bg = "NONE" },
            LualineInactive = { bg = "NONE" },
            StatusLine = { bg = "NONE" },
            StatusLineNC = { bg = "NONE" },
            TabLine = { bg = "NONE" },
            TabLineFill = { bg = "NONE" },
            TabLineSel = { bg = "NONE" },
            WinSeparator = { bg = "NONE" },
            VertSplit = { bg = "NONE" },
            -- Neon blue scope highlight
            MiniIndentscopeSymbol = { fg = "#00ffff" },
          }
        end,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "javascript", "typescript", "python", "bash", "markdown", "hyprlang", "c", "cpp", "qmljs" },
      highlight = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    },
  },

  -- LSP support
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright" },
      })
      
      local servers = { "lua_ls", "ts_ls", "pyright", "qmlls" }
      
      for _, lsp in ipairs(servers) do
        local opts = {}
        if lsp == "qmlls" then
          opts.cmd = { "/usr/bin/qmlls6" }
        end

        if vim.lsp.enable then
          -- Neovim 0.11+ way: avoids require('lspconfig') warning
          if next(opts) ~= nil and vim.lsp.config then
            vim.lsp.config(lsp, opts)
          end
          vim.lsp.enable(lsp)
        else
          -- Fallback for older Neovim versions
          require("lspconfig")[lsp].setup(opts)
        end
      end
      
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client then
            client.server_capabilities.semanticTokensProvider = nil
          end

          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim", -- Professional icons
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      cmp.setup({
        snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif require("luasnip").expand_or_jumpable() then require("luasnip").expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 50,
          })
        }
      })
    end,
  },

  -- Navigation: Harpoon (Quick file switching)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add" })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })
      vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end)
    end,
  },

  -- Navigation: Flash (Fast jumping)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },

  -- Formatting: Conform
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- Diagnostics: Trouble
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    },
  },

  -- Editing: Surround & Todo Comments
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", config = true },
  { "folke/todo-comments.nvim", dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },

  -- UI: Bufferline
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        offsets = { { filetype = "NvimTree", text = "File Explorer", text_align = "left", separator = true } },
        separator_style = "slant",
      }
    }
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    opts = function()
      return {
        options = {
          theme = "auto",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      }
    end,
  },

  -- File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle Explorer" } },
    opts = { filters = { dotfiles = false }, view = { width = 30 } },
  },

  -- Autopairs, Gitsigns, Comment
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  { "lewis6991/gitsigns.nvim", config = true },
  { "numToStr/Comment.nvim", config = true },

  -- Dashboard
  {
    "goolord/alpha-nvim",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.startify")
      dashboard.section.header.val = {
        "   ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
        "   ████╗  ██║██║   ██║██║████╗ ████║",
        "   ██╔██╗ ██║██║   ██║██║██╔████╔██║",
        "   ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "   ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
      }
      alpha.setup(dashboard.config)
    end,
  },

  -- Indent Guides (Background)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = false }, -- Disable IBL scope to use mini.indentscope
    },
  },

  -- Current Scope Highlight (Prominent line)
  {
    "echasnovski/mini.indentscope",
    version = false, -- wait for next release
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      symbol = "│",
      options = { try_as_border = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "help", "alpha", "dashboard", "nvim-tree", "Trouble", "lazy", "mason", "toggleterm" },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },

  -- UI (Noice)
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.set_autocmds"] = true, ["sysext.lsp.util.stylize_markdown"] = true, ["cmp.entry.get_documentation"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true, inc_rename = false, lsp_doc_border = true },
    },
  },

  -- Keybinding Helper (Which-Key)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
