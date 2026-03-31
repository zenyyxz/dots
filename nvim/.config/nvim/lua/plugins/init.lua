return {
  -- Color scheme (Catppuccin to match your rice)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true,
        integrations = {
          alpha = true,
          cmp = true,
          gitsigns = true,
          indent_blankline = {
            enabled = true,
            scope_color = "", -- catppuccin color (eg. `lavender`)
          },
          lualine = true,
          mason = true,
          noice = true,
          notify = true,
          nvimtree = true,
          telescope = {
            enabled = true,
            -- style = "nvchad"
          },
          which_key = true,
        }
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "javascript", "typescript", "python", "bash", "markdown", "hyprlang" },
      highlight = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  },

  -- Telescope for fuzzy finding
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
      
      -- Use nvim 0.11+ native LSP config if available
      local servers = { "lua_ls", "ts_ls", "pyright" }
      for _, lsp in ipairs(servers) do
        if vim.lsp.enable then
          vim.lsp.enable(lsp)
        else
          require("lspconfig")[lsp].setup({})
        end
      end
      
      -- LSP Keybindings
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
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
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        })
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Explorer" },
    },
    config = function()
      require("nvim-tree").setup({
        filters = { dotfiles = false },
        view = { width = 30 },
      })
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = true,
  },

  -- Commenting utility (gcc to comment line, gc in visual mode)
  {
    "numToStr/Comment.nvim",
    config = true,
  },

  -- Dashboard
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.startify")
      dashboard.section.header.val = {
        "                                ",
        "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                ",
      }
      alpha.setup(dashboard.config)
    end,
  },

  -- Indent Guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│", -- Use a standard thin vertical line
        tab_char = "│",
      },
      scope = { enabled = false }, -- Disable scope highlighting to fix the box/rendering issue
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "nvimtree",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
        },
      },
    },
  },

  -- UI Enhancements (Noice)
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        config = function()
          require("notify").setup({
            background_colour = "#000000",
            render = "compact",
          })
        end,
      },
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.set_autocmds"] = true,
          ["sysext.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true, -- This makes the command line float in the center
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true, -- Adds a nice border to documentation popups
      },
    },
  },

  -- Keybinding Helper
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },
}
