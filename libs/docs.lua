local fs = require 'fs'
local re = require 're'
local json = require 'json'
local join = require 'pathjoin'.pathJoin

local exists, scandir = fs.existsSync, fs.scandirSync
local read, write = fs.readFileSync, fs.writeFileSync
local decode, encode = json.decode, json.encode
local insert, concat = table.insert, table.concat

local compile = re.compile

local configs = require 'configs'
local WIKI_BASE = configs.wiki_base

local grammar = [[
  all <- {| class / method / property |}

  property <- '@p' {:_type: '' -> 'property' :} spaces {:name: {%S+} :} spaces {:types: types :} spaces {:description: .+ :}

  method <- '@m' {:_type: '' -> 'method' :} spaces {:name: {%S+} :} spaces tags? parameters? returns? description?
  returns <- %nl '@r' spaces {:returns: types :}

  class <- '@c' {:_type: '' -> 'class' :} spaces {:name: %S+ :} spaces parents? tags? method_tags? parameters? description?
  parents <- {:parents: {| ('x' spaces {%S+} spaces)+ |} :}
  method_tags <- %nl '@mt' spaces {:method_tags: {%S+} :}

  parameters <- {:parameters: {| ({| (%nl '@' {:optional: 'o'? -> optional :} 'p' spaces {:name: %S+ :} spaces {:types: types :}) |})+ |} :}
  tags <- %nl {:tags: {| '@t' (spaces {%S+})+ |} :}
  types <- {| ({[^/%s]+} '/'?)+ |}
  description <- %nl '@d' spaces {:description: {.+} :}

  spaces <- ' '*
]]
local pattern = compile(grammar, {
  optional = function(o) return o == 'o' end
})

---@alias doc_class {name: string, description: string, parents?: string[], tags?: string[], method_tags?: string[], methods: method[], properties: property[], link: string, parameters?: param[]}
---@alias method {name: string, description: string, tags?: string[], parameters?: param[], returns?: string[], link: string, class_name: string}
---@alias param {name: string, types: string[], optional: boolean}
---@alias property {name: string, types: string[], description: string, link: string}

local docs = {}

--- Parses a string containing doc-comments.
--- This assumes the string only contains one and only one class definition.
---@param str string
---@return doc_class|nil
function docs.extract(str)
  local methods, properties = {}, {}
  ---@type doc_class
  local class

  -- match against every comment block
  for block in str:gmatch('%-%-%[=%[\n?(.-)\n?%]=%]') do
    local parsed = pattern:match(block)
    if not parsed then
      error('failed to parse: ' .. block)
    end
    local type = parsed._type

    if type == 'class' then
      class = parsed
    elseif type == 'method' then
      insert(methods, parsed)
    elseif type == 'property' then
      insert(properties, parsed)
    else
      error('unhandled type: ' .. tostring(type))
    end
  end

  if not class then return end
  class.methods = methods
  class.properties = properties
  class.link = WIKI_BASE .. class.name

  -- add method.class_name and method.link
  for _, method in ipairs(class.methods) do
    method.class_name = class.name
    local param_str = {}
    if method.parameters then
      for _, param in ipairs(method.parameters) do
        insert(param_str, param.name)
      end
    end
    param_str = concat(param_str, '-')
    method.link = class.link .. '#' .. method.name .. param_str
  end
  -- add property.class_name and property.link
  for _, property in ipairs(class.properties) do
    property.class_name = class.name
    property.link = class.link .. '#properties'
  end

  return class
end

--- Recursively scan the supplied directory for Lua files, then feeds each file into [extract], returning an array of the results.
---@param dir string
---@param results? table # A cache used for recursion
---@return doc_class[]
function docs.scanDir(dir, results)
  assert(exists(dir))
  results = results or {}
  for entry, typ in scandir(dir) do
    if typ == 'directory' then
      docs.scanDir(join(dir, entry), results)
    elseif entry:match('%.lua$') and (typ == 'file' or typ == 'link') then
      local content = assert(read(join(dir, entry)))
      local result = docs.extract(content)
      if result then
        insert(results, result)
      end
    end
  end
  return results
end

local function inherit(class, parent)
  if not parent then return end
  local class_name = class.name:lower()
  -- inherit methods
  for _, method in pairs(parent.methods) do
    local method_name = method.name:lower()
    if not docs.methods_map[class_name][method_name] then
      insert(class.methods, method)
      insert(docs.method_names_array[class_name], method.name)
      docs.methods_map[class_name][method_name] = method
    end
  end
  -- inherit properties
  for _, property in ipairs(parent.properties or {}) do
    local property_name = property.name:lower()
    if not docs.properties_map[class_name][property_name] then
      insert(class.properties, property)
      insert(docs.property_names_array[class_name], property.name)
      docs.properties_map[class_name][property_name] = property
    end
  end
end

--- Loads the classes by building the necessarily maps and arrays, and makes them available through `docs`.
---@param classes doc_class[]
function docs.load(classes)
  docs.raw_classes = classes
  ---@type table<string, doc_class>
  docs.classes_map = {}
  ---@type table<string, table<string, method>>
  docs.methods_map = {}
  ---@type table<string, table<string, property>>
  docs.properties_map = {}

  ---@type string[]
  docs.class_names_array = {}
  ---@type table<string, string[]>
  docs.method_names_array = {}
  ---@type table<string, string[]>
  docs.property_names_array = {}

  -- build maps and arrays used in various stages
  -- we use method and properties arrays for autocomplete, and the maps for indexing 
  for _, class in ipairs(docs.raw_classes) do
    local class_name = class.name:lower()
    docs.classes_map[class_name] = class -- add the class to classes map

    docs.method_names_array[class_name] = {}
    docs.property_names_array[class_name] = {}
    insert(docs.class_names_array, class.name)

    -- populate methods cache and map
    local map = {}
    for _, method in ipairs(class.methods) do
      local method_name = method.name
      map[method_name:lower()] = method
      insert(docs.method_names_array[class_name], method_name)
    end
    docs.methods_map[class_name] = map

    -- populate properties cache and map
    map = {}
    for _, property in ipairs(class.properties) do
      local property_name = property.name
      map[property_name:lower()] = property
      insert(docs.property_names_array[class_name], property_name)
    end
    docs.properties_map[class_name] = map
  end

  -- modify each class to include inherited methods and proprties from parents
  for _, class in ipairs(docs.raw_classes) do
    for _, parent in ipairs(class.parents or {}) do
      local parent_class = docs.getClass(parent)
      inherit(class, parent_class)
    end
  end

  -- a special exception for Member class
  local member_class = docs.getClass('member')
  local user_class = docs.getClass('user')
  inherit(member_class, user_class)
end

--- Similar to [docs.load] except that it extract the classes from a directory using [docs.scanDir].
---@param path string
function docs.loadFromDir(path)
  docs.load(docs.scanDir(path))
end

--- Similar to [docs.lua] except that it extracts the classes from a pre-saved JSON file saved with [docs.saveJson].
---@param path string
function docs.loadFromJson(path)
  local contents = assert(read(path))
  docs.load(assert(decode(contents)))
end

--- Dumps the classes into a JSON file.
---@param path string # The JSON file path.
function docs.saveJson(path)
  assert(write(path, encode(docs.raw_classes)))
end

--- Searches for a class structure by name.
---@return doc_class?, string?
function docs.getClass(class_name)
  class_name = class_name:lower()
  local class = docs.classes_map[class_name]
  if class then
    return class, class_name
  end
end

--- Searches for a class method using its name.
---@return method?
function docs.getMethod(class_name, method_name)
  local class, lowered_name
  if class_name.name then
    class, lowered_name = class_name, class_name.name:lower()
  else
    class, lowered_name = docs.getClass(class_name)
  end
  if class then
    return docs.methods_map[lowered_name][method_name:lower()]
  end
end

--- Searches for a class property using its name.
---@return property?
function docs.getProperty(class_name, property_name)
  local class, lowered_name
  if class_name.name then
    class, lowered_name = class_name, class_name.name:lower()
  else
    class, lowered_name = docs.getClass(class_name)
  end
  if class then
    return docs.properties_map[lowered_name][property_name:lower()]
  end
end

--- Takes an array of strings representing types and resolves them into classes if applicable.
--- The returned array order matches the input array order, so `returns[1]` is the resolved type of `types[1]`.
---@param types string[]
---@return table<string, string|doc_class>
function docs.resolveTypes(types)
  local result = {}
  for _, typ in ipairs(types) do
    local class = docs.classes_map[typ:lower()]
    if class then
      insert(result, class)
    else
      insert(result, typ)
    end
  end
  return result
end

return docs
