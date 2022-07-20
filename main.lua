local discordia = require 'discordia'
local Stopwatch = discordia.Stopwatch
discordia.extensions()

local fs = require 'fs'
local write, exists = fs.writeFileSync, fs.existsSync

local configs = require 'configs'
local cache = require 'cache'
local docs = require 'docs'
require 'slash'

local JSON_PATH = configs.docs_cache_path
local MAX_AUTOCOMPLETE = 25

local client = discordia.Client(configs.client_options)

---@type fun(self: Client, name: string, description: string, options?: commandoptions[], guild?: string): slashcommand?, string?
local createSlashCommand = client.createSlashCommand

-- Check whether `git` is accessible or not
do
  local spawn = require 'coro-spawn'
  local success, err = spawn(configs.git_binary, {})
  if not success then
    if err:match('^ENOENT:') then
      client:error('Cannot access the git executable. Make sure that git is installed and configs.git_binary is correct!')
    else
      client:error('Cannot spawn git: ' .. err)
    end
    process:exit(-1)
  end
end

-- Initialize cache if it wasn't already
if not cache.isInitialized() then
  local stopwatch = Stopwatch()

  client:info('Cloning %s into cache...', configs.repo_url)
  cache.initialize()
  client:info('Done in %s.\n', stopwatch:getTime():toString())
  stopwatch:reset()

  client:info('Parsing doc comments...')
  docs.loadFromDir(configs.generate_docs_from)
  client:info('Done in %s.\n', stopwatch:getTime():toString())
  stopwatch:reset()

  client:info('Caching docs to disk...')
  docs.saveJson(JSON_PATH)
  client:info('Done in %s.\n', stopwatch:getTime():toString())
  stopwatch:stop()
end

-- Load the cached docs, if wasn't already loaded
if not docs.raw_classes then
  local stopwatch = Stopwatch()
  client:info('Loading classes...')
  -- check if the json file exists. It should always exists at this point in execution
  -- if it wasn't there, it was most likely deleted by the user
  if not exists(JSON_PATH) then
    client:warning('JSON file is missing at: %s.\nCreating an empty one...', JSON_PATH)
    assert(write(JSON_PATH, '{}'))
  end
  -- read and parse the json
  docs.loadFromJson(JSON_PATH)
  -- report success
  client:info('Done in %s.\n', stopwatch:getTime():toString())
  stopwatch:stop()
end

-- Load the commands
local commands = require 'commands'

-- Slash commands handler
client:once('ready', function()
  -- register the command
  for _, command in pairs(commands) do
    local cmd, err = createSlashCommand(client, command.name, command.description, command.options, '613745977941164043')
    if not cmd then
      client:error('Attempt to register "%s" command failed: %s', command.name, err)
    end
  end

  -- handle the command callback and runtime errors
  ---@param intr Interaction
  client:on('slashCommand', function(intr)
    local command = commands[intr.data.name]
    if not command then
      return client:warning('Received an unregistered slash command "%s"', intr.data.name)
    end
    local success, err = pcall(command.callback, intr)
    if not success then
      return client:error('Command %s had an error while executing: %s', command.name, err)
    end
  end)

  -- handle autocomplete, when we can
  client:on('slashCommandAutocomplete', function(intr)
    -- find the used command structure
    local command = commands[intr.data.name]
    if not command then
      return client:warning('Received an autocomplete for unregistered slash command "%s"', intr.data.name)
    end

    -- search for the focused option, if any.
    -- and make sure the option is of type string
    local focused_option
    for _, option in ipairs(intr.data.options or {}) do
      if option.focused then focused_option = option; break end
    end
    if not focused_option or focused_option.type ~= 3 then return end
    local input = focused_option.value

    -- find the autocomplete list the command provides
    local available_autocomplete = command.autocomplete and command.autocomplete[focused_option.name]
    if not available_autocomplete then
      return client:warning('Received an autocomplete for command "%s" which has no autocomplete defined', intr.data.name, focused_option.name)
    end

    -- if the defined autocomplete is a function, call it
    if type(available_autocomplete) == 'function' then
      available_autocomplete = available_autocomplete(intr.data.options)
    end
    if not available_autocomplete or #available_autocomplete < 1 then
      return intr:autocomplete{}
    end

    -- subsequence match inputs
    ---@truemedian thanks for providing this algorithm
    local autocomplete = {}
    local subsequence = input:lower()
    for j = 1, #available_autocomplete do
      if #autocomplete >= MAX_AUTOCOMPLETE then break end
      local str = available_autocomplete[j]:lower()
      local matches = 0
      for i = 1, #str do
        if subsequence:byte(matches + 1) == str:byte(i) then
          matches = matches + 1
        end
      end
      if matches == #subsequence then
        autocomplete[#autocomplete+1] = {
          name = available_autocomplete[j],
          value = available_autocomplete[j],
        }
      end
    end

    if #autocomplete > 0 then
      intr:autocomplete(autocomplete)
    else
      intr:autocomplete{}
    end
  end)
end)

client:run(configs.token)
