-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable Nerd Font support for icons
vim.g.have_nerd_font = true

-- [[ UI & Minimalist Options ]]
vim.opt.number = false         -- No line numbers
vim.opt.relativenumber = false -- No relative numbers
vim.opt.signcolumn = 'no'      -- No gutter (sidebar)
vim.opt.cursorline = true      -- Highlight the current line
vim.opt.scrolloff = 10         -- Keep cursor centered
vim.opt.mouse = 'a'            -- Enable mouse
vim.opt.showmode = false       -- Mode shown in statusline
vim.opt.breakindent = true     -- Enable break indent
vim.opt.undofile = true        -- Save undo history
vim.opt.ignorecase = true      -- Case-insensitive search
vim.opt.smartcase = true       -- Smart search case
vim.opt.splitright = true      -- Vertical splits to the right
vim.opt.splitbelow = true      -- Horizontal splits below
vim.opt.list = true            -- Show certain whitespace
vim.opt.listchars = { tab = '» ', trail = '·', multispace = '┊' }
vim.opt.inccommand = 'split'   -- Preview substitutions
vim.opt.timeoutlen = 300       -- Faster popup response
vim.opt.updatetime = 250       -- Faster diagnostic updates

-- Disable built-in file explorer (Oil.nvim will take over)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Sync clipboard after UI enters
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- [[ Basic Keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Buffer management: Close buffer and return to Oil directory
local function smart_bd(opts)
  local ok_oil, oil = pcall(require, 'oil')
  local current_buf = vim.api.nvim_get_current_buf()

  -- Handle potential buffer target from command arguments (e.g. :bd 3)
  local target_buf = current_buf
  if opts.args and opts.args ~= '' then
    local arg_buf = vim.fn.bufnr(opts.args)
    if arg_buf ~= -1 then
      target_buf = arg_buf
    else
      vim.api.nvim_err_writeln('E94: No matching buffer for ' .. opts.args)
      return
    end
  end

  local target_file = vim.api.nvim_buf_get_name(target_buf)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = target_buf })

  -- Case 1: We are in an Oil buffer. Navigate up, but stop at project root or CWD.
  if ok_oil and target_file:find '^oil://' and target_buf == current_buf then
    local current_dir = oil.get_current_dir()
    if current_dir then
      -- Get git root safely
      local git_root = vim.fn.systemlist('git rev-parse --show-toplevel 2>/dev/null')[1]
      local boundary = (git_root and git_root ~= "") and git_root or vim.fn.getcwd()
      
      -- Normalize paths: remove trailing slashes and ensure absolute
      local function normalize(p) return vim.fn.fnamemodify(p, ':p'):gsub('[/\\]$', '') end
      local abs_current = normalize(current_dir)
      local abs_boundary = normalize(boundary)

      -- If we are NOT at the boundary, go up exactly one level
      if abs_current ~= abs_boundary and abs_current ~= "" and abs_current ~= "/" then
        oil.open(vim.fn.fnamemodify(abs_current, ':h'))
      end
      -- If we are at the boundary, stay here.
    end
    return
  end

  -- Case 2: Special buffers, blank buffers, or not the current buffer. Just delete.
  if not ok_oil or target_buf ~= current_buf or target_file == '' or buftype ~= '' or target_file:find '^oil://' then
    local force_bang = opts.bang and '!' or ''
    local ok, err = pcall(vim.cmd, 'bd' .. force_bang .. ' ' .. target_buf)
    if not ok and err then
      vim.api.nvim_err_writeln(err)
    end
    return
  end

  -- Case 3: Regular file buffer. Open its directory in Oil, then delete.
  local dir = vim.fn.fnamemodify(target_file, ':p:h')
  oil.open(dir)

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(target_buf) then
      pcall(vim.api.nvim_buf_delete, target_buf, { force = opts.bang })
    end
  end)
end

vim.api.nvim_create_user_command('Bd', smart_bd, { bang = true, nargs = '?', desc = 'Delete buffer and return to Oil' })
vim.keymap.set('n', '<leader>bd', '<cmd>Bd<CR>', { desc = '[B]uffer [D]elete (Smart)' })

-- Robustly hook :bd and :bdelete to :Bd
vim.cmd [[
  cnoreabbrev <expr> bd ((getcmdtype() == ':' && getcmdline() == 'bd') ? 'Bd' : 'bd')
  cnoreabbrev <expr> bd! ((getcmdtype() == ':' && getcmdline() == 'bd!') ? 'Bd!' : 'bd!')
  cnoreabbrev <expr> bdelete ((getcmdtype() == ':' && getcmdline() == 'bd') ? 'Bd' : 'bdelete')
  cnoreabbrev <expr> bdelete! ((getcmdtype() == ':' && getcmdline() == 'bdelete!') ? 'Bd!' : 'bdelete!')
]]

-- Window Navigation (CTRL + hjkl)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- [[ Diagnostic Configuration ]]
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = true,
  jump = { float = true },
}

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
require('lazy').setup({
  'tpope/vim-sleuth',

  { 'folke/lazydev.nvim', ft = 'lua', opts = {} },

  { 'numToStr/Comment.nvim', opts = {} },

  { -- Which-key
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  { -- Telescope
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('telescope').setup {
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'file_browser')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>fb', ':Telescope file_browser<CR>', { desc = '[F]ile [B]rowser' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = '[/] Fuzzily search in current buffer' })
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- Oil.nvim (Minimalist directory explorer)
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup({
        default_file_explorer = true,
        columns = { 'icon' },
        keymaps = {
          ['-'] = 'actions.parent',
          ['_'] = 'actions.open_cwd',
          ['<BS>'] = 'actions.parent',
          ['h'] = 'actions.parent',
          ['l'] = 'actions.select',
        },
        view_options = {
          -- Show the parent directory ".." in the view
          is_hidden_file = function(name, bufnr)
            if name == ".." then return false end
            return vim.startswith(name, ".")
          end,
        },
      })
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
  },

  { 'wakatime/vim-wakatime', lazy = false },

  { -- Zen Mode
    'folke/zen-mode.nvim',
    dependencies = { 'folke/twilight.nvim' },
    keys = { { '<leader>z', '<cmd>ZenMode<cr>', desc = '[Z]en Mode' } },
    opts = { window = { width = 0.85, options = { number = false, relativenumber = false, signcolumn = 'no' } } },
  },

  -- Supermaven AI Autocomplete
  {
    'supermaven-inc/supermaven-nvim',
    opts = { keymaps = { accept_suggestion = '<Tab>', clear_suggestion = '<C-]>', accept_word = '<C-j>' } },
  },

  { -- LSP
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, '[T]oggle Inlay [H]ints')
        end,
      })

      local servers = {
        clangd = {}, pyright = {}, ts_ls = {}, bashls = {}, jsonls = {}, stylua = {},
        lua_ls = { settings = { Lua = { workspace = { checkThirdParty = false } } } },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'black', 'prettier', 'shfmt' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    opts = {
      format_on_save = { timeout_ms = 500, lsp_format = 'fallback' },
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'black' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        json = { 'prettier' },
        bash = { 'shfmt' },
      },
    },
    config = function(_, opts)
      require('conform').setup(opts)
      vim.keymap.set('n', '<leader>f', function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end, { desc = '[F]ormat buffer' })
    end,
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'L3MON4D3/LuaSnip', 'onsails/lspkind.nvim' },
    opts = {
      keymap = { preset = 'default' },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      completion = { ghost_text = { enabled = true } },
    },
  },

  { -- Colorscheme
    'folke/tokyonight.nvim',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'tokyonight-night'
      vim.api.nvim_set_hl(0, 'Comment', { italic = true })
    end,
  },

  { -- Treesitter (Aligned with Upstream Modern API)
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    config = function()
      -- ensure basic parser are installed
      local parsers = {
        'bash',
        'c',
        'cpp',
        'diff',
        'html',
        'java',
        'javascript',
        'json',
        'kotlin',
        'latex',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'typescript',
        'vim',
        'vimdoc',
      }
      require('nvim-treesitter').install(parsers)

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- check if parser exists and load it
        if not vim.treesitter.language.add(language) then
          return
        end
        -- enables syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- enables treesitter based folds
        -- for more info on folds see `:help folds`
        -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        -- vim.wo.foldmethod = 'expr'

        -- enables treesitter based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      local available_parsers = require('nvim-treesitter').get_available()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then
            return
          end

          local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

          if vim.tbl_contains(installed_parsers, language) then
            -- enable the parser if it is installed
            treesitter_try_attach(buf, language)
          elseif vim.tbl_contains(available_parsers, language) then
            -- if a parser is available in `nvim-treesitter` auto install it, and enable it after the installation is done
            require('nvim-treesitter').install(language):await(function()
              treesitter_try_attach(buf, language)
            end)
          else
            -- try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
            treesitter_try_attach(buf, language)
          end
        end,
      })
    end,
  },

  { import = 'kickstart.plugins' },
  { import = 'custom.plugins' },
}, { ui = { icons = vim.g.have_nerd_font and {} or { cmd = '⌘', config = '🛠', ft = '📂', lazy = '💤 ' } } })

-- vim: ts=2 sts=2 sw=2 et
