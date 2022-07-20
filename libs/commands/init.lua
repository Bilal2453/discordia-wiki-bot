-- load the commands by requiring them
local commands = {
  ---@module 'commands/cache-refresh'
  ['cache-refresh'] = require './cache-refresh',
  ---@module 'commands/class'
  class = require './class',
  ---@module 'commands/method'
  method = require './method',
  ---@module 'commands/property'
  property = require './property',
  ---@module 'commands/wiki'
  wiki = require './wiki',
}

local all_commands = {}

-- TODO: rewrite this using scandir
-- TODO: remove aliases handling

-- load the aliases of each command
for name, command in pairs(commands) do
  all_commands[name] = command
  if command.aliases then
    for _, alias in ipairs(command.aliases) do
      commands[alias] = command
    end
  end
end

return all_commands, commands
