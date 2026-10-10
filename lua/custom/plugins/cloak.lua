vim.pack.add { 'https://github.com/fam007e/cloak.nvim' }

require('cloak').setup {
  enabled = true,
  cloak_character = '*',
  highlight_group = 'Comment',
  cloak_telescope = true,
  cloak_snacks = false,
  cmp_exact = false,
  cloak_on_leave = false,
  cloak_wrap = true,
  patterns = {
    {
      file_pattern = {
        '.env*',
        '*.env',
        '*.env.*',
        'wrangler.toml',
        '.dev.vars',
        '*.properties',
        'terraform.tfvars',
        '*.secret.toml',
      },
      cloak_pattern = '=.+',
    },
    {
      file_pattern = {
        '*.secret.json',
        '*.secret.yaml',
        '*.secret.yml',
        'secrets.json',
        'secrets.yaml',
        'secrets.yml',
      },
      cloak_pattern = ':.+',
    },
    {
      file_pattern = {
        '.env*',
        '*.pem',
        '*.key',
      },
      multiline = true,
      -- Lazy match from the BEGIN line to the newline preceding the END marker.
      -- (An earlier version used '[%s%S]-+-----END'; that also matched because the
      -- trailing '+-' parses as a lazily-repeated literal '+', but it was needlessly obscure.)
      cloak_pattern = '-----BEGIN[^\n]+\n[%s%S]-\n-----END[^\n]+',
    },
  },
}

-- Keymaps: toggle masking (under the <leader>t toggle group), or reveal only the current line
vim.keymap.set('n', '<leader>tc', '<cmd>CloakToggle<cr>', { desc = '[T]oggle [C]loak' })
vim.keymap.set('n', '<leader>cp', '<cmd>CloakPreviewLine<cr>', { desc = '[C]loak: [P]review line' })
