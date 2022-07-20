local docs = require 'docs'
local getClass = docs.getClass
local getMethod = docs.getMethod
local getProperty = docs.getProperty

local utils = {}

function utils.checkClass(intr, target_class)
  local class = getClass(target_class)
  if not class then
    intr:reply('No such class "' .. target_class .. '"', true)
  end
  return class
end

function utils.checkMethod(intr, target_class, target_method)
  local class = utils.checkClass(intr, target_class)
  if not class then return end
  local method = getMethod(class, target_method)
  if not method then
    intr:reply('No such method "' .. target_method .. '" in the specified class', true)
  end
  return method, class
end

function utils.checkProperty(intr, target_class, target_property)
  local class = utils.checkClass(intr, target_class)
  if not class then return end
  local property = getProperty(class, target_property)
  if not property then
    intr:reply('No such property "' .. target_property .. '" in the specified class', true)
  end
  return property, class
end

return utils
