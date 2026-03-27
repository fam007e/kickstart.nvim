return {
  'fam007e/cloak.nvim',
  branch = 'main',
  config = function()
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
          -- FIX: The original pattern was '-----BEGIN[^\n]+\n[%s%S]-+-----END[^\n]+'.
          -- In Lua patterns, after a quantified item like [%s%S]- (lazy zero-or-more),
          -- the following + has no item to quantify and is treated as a literal '+'.
          -- This meant the pattern only matched PEM blocks where the last base64
          -- character happened to be '+' -- effectively never cloaking PEM keys.
          --
          -- The fix: replace -+ with -\n so the lazy body match expands until it
          -- finds the newline that precedes the -----END marker. This correctly
          -- matches the full block body regardless of its base64 content.
          cloak_pattern = '-----BEGIN[^\n]+\n[%s%S]-\n-----END[^\n]+',
        },
      },
    }
  end,
}
