-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Iterate over all Lua files in the plugins directory and load them.
-- `vim.fs.dir()` iteration order is unspecified and must not be relied upon.
-- Each module is loaded in isolation so one broken file does not prevent the others from loading.
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, file_type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (file_type == 'file' or file_type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    local ok, err = pcall(require, 'custom.plugins.' .. module)
    if not ok then vim.notify(('custom.plugins.%s failed:\n%s'):format(module, err), vim.log.levels.ERROR) end
  end
end
