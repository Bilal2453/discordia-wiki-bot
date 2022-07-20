local docs = require 'docs'
local response = require 'response'
local class_names = docs.class_names_array
local method_names = docs.method_names_array

local utils = require 'commands/utils'
local checkMethod = utils.checkMethod

local function callback(intr)
  local options = intr.data.options

  -- define the inputs
  local target_class = options[1].value
  local target_method = options[2].value
  local target_user = options[3] and options[3].value

  -- find the targeted method
  local method = checkMethod(intr, target_class, target_method)

  intr:reply(response.method(method, target_user))
end


return {
  callback = callback,
  name = 'method',
  description = 'Posts the documentation about a specific class method',
  ---@type commandoptions[]
  options = {
    {
      type = 3,
      name = 'class',
      description = 'The class containing the method.',
      required = true,
      autocomplete = true,
    },
    {
      type = 3,
      name = 'method',
      description = 'The name of the method you want to look up.',
      required = true,
      autocomplete = true,
    },
    {
      type = 6,
      name = 'target',
      description = 'Reply to this user with the command\'s result.',
      required = false,
    },
  },
  autocomplete = {
    class = class_names,
    method = function(options)
      return method_names[options[1].value:lower()]
    end,
  },
}
