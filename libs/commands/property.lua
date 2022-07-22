local docs = require 'docs'
local response = require 'response'
local class_names = docs.class_names_array
local property_names = docs.property_names_array

local utils = require 'commands/utils'
local checkProperty = utils.checkProperty

local function callback(intr)
  local options = intr.data.options

  -- define the inputs
  local target_class = options[1].value
  local target_property = options[2].value
  local target_user = options[3] and options[3].value

  -- find the specified property and reply
  local property = checkProperty(intr, target_class, target_property)
  if not property then return end
  intr:reply(response.property(property, target_user))
end


return {
  callback = callback,
  name = 'property',
  description = 'Posts the documentation about a specific class property',
  ---@type commandoptions[]
  options = {
    {
      type = 3,
      name = 'class',
      description = 'The class containing the property',
      required = true,
      autocomplete = true,
    },
    {
      type = 3,
      name = 'property',
      description = 'The name of the property you want to look up',
      required = true,
      autocomplete = true,
    },
    {
      type = 6,
      name = 'target',
      description = 'Reply to this user with the command\'s result',
      required = false,
    },
  },
  autocomplete = {
    class = class_names,
    property = function(options)
      return property_names[options[1].value:lower()]
    end,
  },
}
