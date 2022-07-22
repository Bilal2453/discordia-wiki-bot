local docs = require 'docs'
local resolveTypes = docs.resolveTypes

local concat, insert = table.concat, table.insert
local INVISIBLE_CHAR = '\226\128\142' -- U+200E

local configs = require 'configs'
local colors = configs.res_colors

local responses = {}

local function handleUser(user)
  return user and '*Here is a wiki page to check out <@' .. user .. '>!*' or nil
end

local function handleTypes(types)
  local res = {}
  types = resolveTypes(types)
  for i, typ in ipairs(types) do
    res[i] = typ.link and '[' .. typ.name .. '](' .. typ.link .. ')' or typ
  end
  return concat(res, '/')
end

local function handleParams(params, fields)
  if not params then return nil, '()' end
  local signature = {}

  fields = fields or {}
  insert(fields, {
    name = INVISIBLE_CHAR,
    value = '**__Parameters__**:',
    inline = false,
  })

  for _, param in ipairs(params) do
    local types = handleTypes(param.types)
    insert(fields, {
      name = param.name .. (param.optional and ' (optional)' or ''),
      value = types,
      inline = true,
    })
    insert(signature, param.name)
  end

  return fields, '(' .. concat(signature, ', ') .. ')'
end

local function handleReturns(returns, fields)
  if not returns then return end

  fields = fields or {}
  insert(fields, {
    name = INVISIBLE_CHAR,
    value = '**__Returns__**:\n' .. handleTypes(returns),
    inline = false,
  })

  return fields
end

local tags_map = {
  http = 'This method always makes an HTTP request.',
  ['http?'] = 'This method may make an HTTP request.',
  ws = 'This method always makes a WebSocket request.',
  mem = 'This method only operates on data in memory.',
  ui = 'This is a user interface class. User can construct instance of this class.',
  abs = 'This is an abstract base class. Direct instances should never exist.',
  nui = 'Instances of this class should not be constructed by users.',
}
local function handleTags(tags)
  local text = ''
  for _, tag in ipairs(tags or {}) do
    if tags_map[tag] then
      text = text .. tags_map[tag] .. '\n'
    end
  end
  if #text > 0 then
    return {text = text}
  end
end

---@param class doc_class
function responses.class(class, user)
  return {
    content = handleUser(user),
    embed = {
      title = class.name,
      url = class.link,
      description = class.description,
      fields = handleParams(class.parameters),
      footer = handleTags(class.tags or {'nui'}),
      color = colors.class,
    }
  }
end

function responses.method(method, user)
  local fields, signature = handleParams(method.parameters)
  handleReturns(method.returns, fields)

  local sep = method.tags and method.tags.static and '.' or ':'
  local footer = handleTags(method.tags)

  return {
    content = handleUser(user),
    embed = {
      title = method.class_name .. sep .. method.name .. signature,
      url = method.link and method.link or nil,
      description = method.description,
      fields = fields,
      footer = footer,
      color = colors.method,
    }
  }
end

function responses.property(property, user)
  return {
    content = handleUser(user),
    embed = {
      title = property.class_name .. '.' .. property.name,
      url = property.link and property.link or nil,
      description = property.description,
      fields = {
        {
          name = 'Type:',
          value = handleTypes(property.types),
          inline = true,
        }
      },
      color = colors.property,
    }
  }
end

return responses
