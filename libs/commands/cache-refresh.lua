local Stopwatch = require 'discordia'.Stopwatch
local configs = require 'configs'
local cache = require 'cache'
local docs = require 'docs'

local allowed_users = configs.refresh_allowed_users or {}
local allowed_roles = configs.refresh_allowed_roles or {}
local refresh = cache.refresh

local stopwatch = Stopwatch(true)

local function isAllowed(intr)
  if intr.user == intr.client.owner then return true end

  -- check the roles if possible
  if next(allowed_roles) and intr.member then
    for role in intr.member.roles:iter() do
      if allowed_roles[role.id] then
        return true
      end
    end
  end

  -- check the ids
  if allowed_users[intr.user.id] then
    return true
  end

  return false
end

local function callback(intr)
  local client = intr.client
  -- reply to the interaction and make sure we should proceed with the operation
  if not intr:replyDeferred(true) then return end

  -- make sure the user is allowed to use this command
  if not isAllowed(intr) then
    intr:reply('You are not allowed to use this command', true)
    return
  end

  client:info('cache-refresh: Refreshing cache...')
  stopwatch:reset()
  stopwatch:start()

  -- pull the latest changes from the configured branch
  local success, err = refresh()

  -- report failure
  if not success then
    client:error('cache-refresh: Failed to refresh the cache: ' .. err)
    intr:reply(err, true)
    stopwatch:stop()
    return
  end

  -- re-generate the classes
  docs.generate()

  -- report success
  local took = stopwatch:getTime():toString()
  client:info('cache-refresh: Done in %s.\n', took)
  intr:reply('Cache successfully refreshed.\nOperation took ' .. took)
  stopwatch:stop()
end

return {
  callback = callback,
  name = 'cache-refresh',
  description = 'Pulls the latest changes from the configured branch and regenerates the cache',
}
