local docs = require 'docs'
local methods_map = docs.methods_map
local properties_map = docs.properties_map
local getClass = docs.getClass
local getMethod = docs.getMethod
local getProperty = docs.getProperty

local response = require 'response'

local queries = {
  -- TODO: special format for properties specifically, and another for methods.
  ['^(%w+)$'] = function(entry_name)
    -- is it a class?
    local class = getClass(entry_name)
    if class then
      return response.class, class
    end
    -- is it a method?
    for _, class_methods in pairs(methods_map) do
      if class_methods[entry_name] then
        return response.method, class_methods[entry_name]
      end
    end
    -- is it a property?
    for _, class_properties in pairs(properties_map) do
      if class_properties[entry_name] then
        return response.property, class_properties[entry_name]
      end
    end
  end,
  ['^(%w+)%p(%w+)$'] = function(class_name, entry_name)
    local class = getClass(class_name)
    if not class then return end
    class = class.name:lower()

    local entry = getMethod(class, entry_name)
    if entry then
      return response.method, entry
    else
      entry = getProperty(class, entry_name)
      if not entry then return end
      return response.property, entry
    end
  end
}

---@param intr Interaction
local function callback(intr)
  local options = intr.data.options

  -- define the inputs
  local query = options[1].value
  local target_user = options[2] and options[2].value

  -- match against the queries patterns 
  for patt, cb in pairs(queries) do
    if query:match(patt) then
      local res, entry = cb(query:match(patt))
      if res then
        return intr:reply(res(entry, target_user))
      end
    end
  end

  intr:reply('Unable to find any matches against query "' .. query .. '"', true)
end

return {
  callback = callback,
  name = 'wiki',
  description = 'Posts documentation about a class or a method or a property.',
  ---@type commandoptions[]
  options = {
    {
      type = 3,
      name = 'query',
      description = 'A search query. This can be of many formats: "class", "method", "class[%p]method".',
      required = true,
    },
    {
      type = 6,
      name = 'target',
      description = 'Reply to this user with the command\'s result.',
      required = false,
    }
  },
}