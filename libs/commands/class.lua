local docs = require 'docs'
local class_names = docs.class_names_array

local utils = require 'commands/utils'
local checkClass = utils.checkClass

local responses = require 'response'

local function callback(intr)
  local options = intr.data.options

  -- define the inputs
  local target_class = options[1].value
  local target_user = options[2] and options[2].value

  -- find the specified class and reply
  local class = checkClass(intr, target_class)
  if not class then return end
  intr:reply(responses.class(class, target_user))
end

return {
  callback = callback,
  name = 'class',
  description = 'Posts the documentation about a specific class',
  ---@type commandoptions[]
  options = {
    {
      type = 3,
      name = 'class',
      description = 'The class of which to post its page',
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
  },
}