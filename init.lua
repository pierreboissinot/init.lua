-- https://github.com/neovim/neovim/blob/master/INSTALL.md#pre-built-archives-2
-- https://gpanders.com/blog/whats-new-in-neovim-0-11/
-- https://lsp-zero.netlify.app/blog/lsp-config-overview.html
-- ~/.config/nvim/init.lua

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ";"
vim.g.maplocalleader = ";"

-- https://phpactor.readthedocs.io/en/master/lsp/vim.html#two-dollars-on-variables
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.opt_local.iskeyword:append("$")
  end,
})

-- https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings

-- https://github.com/mason-org/mason.nvim?tab=readme-ov-file#introduction
-- Packages are installed in Neovim's data directory (:h standard-path) by default.
vim.lsp.config['luals'] = {
    -- Command and arguments to start the server.
    -- be sure to add ~/.local/share/nvim/mason/bin/lua-language-server to PATH
    cmd = { 'lua-language-server' },
    -- Filetypes to automatically attach to.
    filetypes = { 'lua' },
    -- Sets the "root directory" to the parent directory of the file in the
    -- current buffer that contains either a ".luarc.json" or a
    -- ".luarc.jsonc" file. Files that share a root directory will reuse
    -- the connection to the same LSP server.
    -- Nested lists indicate equal priority, see |vim.lsp.Config|.
    root_markers = { '.luarc.json', '.luarc.jsonc' },
    -- Specific settings to send to the server. The schema for this is
    -- defined by the server. For example the schema for lua-language-server
    -- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  }

  vim.lsp.enable('luals')

vim.lsp.config['phpactor'] = {
    -- Command and arguments to start the server.
    -- be sure to add ~/.local/share/nvim/mason/bin/lua-language-server to PATH
    -- fish_add_path /home/pierreboissinot/.local/share/nvim/mason/bin
    cmd = { 'phpactor', 'language-server' },
    filetypes = { 'php' },
    root_markers = { 'composer.json' },
  }

  vim.lsp.enable('phpactor')

  vim.lsp.config['twiggy-language-server'] = {
    cmd = { 'twiggy-language-server', '--stdio' },
    filetypes = { 'twig' },
    root_markers = { 'composer.json' },
  }

  vim.lsp.enable('twiggy-language-server')

  vim.lsp.config['docker-compose-language-service'] = {
    cmd = { 'docker-compose-langserver', '--stdio' },
    filetypes = { 'yaml', 'yml' },
    root_markers = { 'compose.yaml', 'docker-compose.yml' },
  }

  vim.lsp.enable('docker-compose-language-service')

  -- todo: filetype
  vim.lsp.config['dockerfile-language-server'] = {
    cmd = { 'docker-langserver', '--stdio' },
    root_dir = vim.fn.getcwd(), -- or implement your own root finder
    on_attach = function(client, bufnr)
      print("Dockerfile LSP attached to buffer", bufnr)
    end,
  }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "Dockerfile",
    callback = function()
      vim.lsp.start({
        name = 'dockerfile-language-server',
        cmd = { 'docker-langserver', '--stdio' },
        root_dir = vim.fn.getcwd(),
        on_attach = function(client, bufnr)
          print("Dockerfile LSP attached to buffer", bufnr)
        end,
      })
    end,
  })

  -- vim.lsp.enable('dockerfile-language-server')

  vim.lsp.config['phpstan'] = {
    -- todo: handle phpstan project config
    -- cmd = { 'docker', 'run', '--rm', '-v', vim.loop.cwd() .. ':/app', '-w', '/app', 'ghcr.io/phpstan/phpstan:2-php8.3', 'analyse', '--error-format=json', '--no-progress', '--memory-limit=1G' },
    cmd = {
      'sh',
      '-c',
      -- Double-quote $0 to preserve the file argument, redirect stderr
      [[docker run --memory=1g --rm -v ]] .. vim.loop.cwd() .. [[:/app -w /app ghcr.io/phpstan/phpstan:2-php8.3 analyse --error-format=json --no-progress --memory-limit=1G "$0" 2>/dev/null]],
      -- "$0" is replaced by Neovim with the file path when launching the LSP
    },
    filetypes = { 'php' },
    -- root_markers = { 'composer.json' },
    root_markers = {'phpstan.neon', 'phpstan.neon.dist', 'composer.json', '.git'},
  }

  -- vim.lsp.enable('phpstan')

  -- https://lsp-zero.netlify.app/blog/lsp-client-features.html#completion-side-effects
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client:supports_method('textDocument/completion') then
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      end
    end,
  })

--[[
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
  
      if client:supports_method('textDocument/formatting') then
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = args.buf,
          callback = function()
            vim.lsp.buf.format({bufnr = args.buf, id = client.id})
          end,
        })
      end
    end,
  })
]]

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, {bufnr = args.buf})
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client:supports_method('textDocument/documentHighlight') then
      local autocmd = vim.api.nvim_create_autocmd
      local augroup = vim.api.nvim_create_augroup('lsp_highlight', {clear = false})

      vim.api.nvim_clear_autocmds({buffer = bufnr, group = augroup})

      autocmd({'CursorHold'}, {
        group = augroup,
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      autocmd({'CursorMoved'}, {
        group = augroup,
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.opt.completeopt = {'menu', 'menuone', 'noselect', 'noinsert'}
vim.opt.shortmess:append('c')

local function tab_complete()
  if vim.fn.pumvisible() == 1 then
    -- navigate to next item in completion menu
    return '<Down>'
  end

  local c = vim.fn.col('.') - 1
  local is_whitespace = c == 0 or vim.fn.getline('.'):sub(c, c):match('%s')

  if is_whitespace then
    -- insert tab
    return '<Tab>'
  end

  local lsp_completion = vim.bo.omnifunc == 'v:lua.vim.lsp.omnifunc'

  if lsp_completion then
    -- trigger lsp code completion
    return '<C-x><C-o>'
  end

  -- suggest words in current buffer
  return '<C-x><C-n>'
end

local function tab_prev()
  if vim.fn.pumvisible() == 1 then
    -- navigate to previous item in completion menu
    return '<Up>'
  end

  -- insert tab
  return '<Tab>'
end


vim.keymap.set('i', '<Tab>', tab_complete, {expr = true})
vim.keymap.set('i', '<S-Tab>', tab_prev, {expr = true})

-- https://github.com/junegunn/vim-plug?tab=readme-ov-file#unix-linux

-- https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings
-- grn in Normal mode maps to vim.lsp.buf.rename()
-- grr in Normal mode maps to vim.lsp.buf.references()
-- gri in Normal mode maps to vim.lsp.buf.implementation()
-- gO in Normal mode maps to vim.lsp.buf.document_symbol() (this is analogous to the gO mappings in help buffers and :Man page buffers to show a “table of contents”)
-- gra in Normal and Visual mode maps to vim.lsp.buf.code_action()
-- CTRL-S in Insert and Select mode maps to vim.lsp.buf.signature_help()
-- [d and ]d move between diagnostics in the current buffer ([D jumps to the first diagnostic, ]D jumps to the last)


local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')

Plug 'tamton-aquib/zone.nvim'

Plug 'mason-org/mason.nvim'

Plug 'nvim-lua/plenary.nvim' -- telescope dependency

Plug 'nvim-telescope/telescope.nvim'

Plug('nvim-treesitter/nvim-treesitter', { ['do'] = function()
  vim.fn['TSUpdate']()
end })

Plug 'nvim-lualine/lualine.nvim'
--  If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'

Plug 'nvim-treesitter/nvim-treesitter-context'

Plug 'ibhagwan/fzf-lua'

Plug 'folke/trouble.nvim'

Plug 'folke/persistence.nvim'

Plug 'rose-pine/neovim'

Plug 'nvimdev/dashboard-nvim'

Plug 'nvim-telescope/telescope-frecency.nvim'

Plug '/home/pierreboissinot/workspace/github/telescope-symfony'

Plug 'tpope/vim-fugitive'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'fbuchlak/cmp-symfony-router'
-- Plug(vim.fn.expand('~/.config/nvim/lua/cmp-symfony-service'))

-- TODO
-- https://github.com/ThePrimeagen/init.lua
-- https://github.com/laytan/cloak.nvim?tab=readme-ov-file
-- https://github.com/mfussenegger/nvim-dap?tab=readme-ov-file
-- https://github.com/nvim-neotest/neotest
-- https://github.com/mbbill/undotree

vim.call('plug#end')

require("mason").setup({
 -- ensure install phpactor
})

require('zone').setup {
  -- style = "dvd",
  after = 15,          -- Idle timeout
  -- exclude_filetypes = { "TelescopePrompt", "NvimTree", "neo-tree", "dashboard", "lazy" },
}

require('dashboard').setup({
  theme = 'hyper',  -- or 'doom'
  config = {
    header = {
      'Welcome to Neovim!',
      'Let’s be productive 🚀',
    },
    footer = { 'nvim ❤ you' },
  }
})

require("trouble").setup {}

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
vim.keymap.set("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions / references / ... (Trouble)" })
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })



-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
require('telescope').load_extension('frecency')


-- Color schemes should be loaded after plug#end().
-- We prepend it with 'silent!' to ignore errors when it's not yet installed.
-- vim.cmd('silent! colorscheme seoul256')

-- https://lsp-zero.netlify.app/blog/theprimeagens-config-from-2022.html
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user_lsp_attach', {clear = true}),
  callback = function(event)
    local opts = {buffer = event.buf}

    vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
    vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
  end,
})

require'nvim-treesitter.configs'.setup{
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { 
   "bash",
   "blade",
   "caddy",
   "cmake",
   "comment",
   "css",
   "csv",
   "diff",
   "dockerfile",
   "editorconfig",
   "fish",
   "git_config",
   "git_rebase",
   "gitattributes",
   "gitcommit",
   "gitignore",
   "http",
   "hurl",
   "javascript",
   "json",
   "make",
   "php",
   "phpdoc",
   "ssh_config",
   "sql",
   "twig",
   "typescript",
   "vue",
   "xml",
   "yaml",
   "lua",
    "vim", 
    "vimdoc",
    "query",
    "markdown", 
    "markdown_inline"
   },
  highlight={enable=true}
}  -- At the bottom of your init.vim, keep all configs on one line

-- Optional: configure theme before loading
require("rose-pine").setup({
  variant = "auto",     -- auto, main, moon, or dawn
  dark_variant = "main",
  styles = {
    bold = true,
    italic = true,
    transparency = false,
  },
})

-- Enable 24-bit color
vim.o.termguicolors = true

-- Set the colorscheme
vim.cmd("colorscheme rose-pine")

local actions = require("telescope.actions")
local open_with_trouble = require("trouble.sources.telescope").open

-- Use this to add more results without clearing the trouble list
local add_to_trouble = require("trouble.sources.telescope").add

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = open_with_trouble },
      n = { ["<c-t>"] = open_with_trouble },
    },
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',         -- ← this includes hidden files
      '--glob',
      '!.git/*'           -- ← optionally exclude .git directory
  },
  },
  pickers = {
    find_files = {
      find_command = { "rg", "--ignore", "--hidden", "--files" }
    }
  }
})

local trouble = require("trouble")
local symbols = trouble.statusline({
  mode = "lsp_document_symbols",
  groups = {},
  title = false,
  filter = { range = true },
  format = "{kind_icon}{symbol.name:Normal}",
  hl_group = "lualine_c_normal", -- Fix background color
})

require("lualine").setup({
  options = {
    theme = "auto", -- or "rose-pine", "tokyonight", etc.
    section_separators = '',
    component_separators = '',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = {
      'filename',
      { symbols.get, cond = symbols.has },
    },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

-- Require cmp and symfony-router source
local cmp = require('cmp')

-- Register the source before cmp.setup
-- cmp.register_source("symfony_services", require("cmp-symfony-service").new())

require('cmp').setup({
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { 
      name = "symfony_router",
            -- these options are default, you don't need to include them in setup
            option = {
                console_command = { "docker", "compose", "exec", "php", "php", "bin/console" }, -- see Configuration section
                cwd = nil, -- string|nil Defaults to vim.loop.cwd()
                cwd_files = { "composer.json", "bin/console" }, -- all these files must exist in cwd to trigger completion
                filetypes = { "php", "twig" },
            }
    },
    -- other sources like buffer, path, etc.
    { name = 'buffer' },
    { name = 'nvim_lsp' },
    {
      name = 'symfony_services',
      keyword_pattern = [[@\k*]],
      trigger_characters = { '@' },
      option = {
        docker_command = { "docker", "compose", "exec", "php" },
        cwd = nil,
        cwd_files = { "composer.json", "bin/console" },
        filetypes = { "php", "twig" }
      }
    },
  }),
})

