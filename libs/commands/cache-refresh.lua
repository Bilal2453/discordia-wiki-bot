local Stopwatch = require 'discordia'.Stopwatch
local configs = require 'configs'
local cache = require 'cache'
local docs = require 'docs'

local refresh = cache.refresh
local remove = cache.remove

local CMD_COLOR  = 0xcceecc
local FAIL_COLOR = 0xddaaaa
local FAIL_TITLE = 'Failed to refresh cache:'
local SUCCESS_TITLE = 'Cache successfully refreshed.'

local stopwatch = Stopwatch(true)

-- TODO: rewrite, like really

---@param intr Interaction
local function callback(intr)
  local client = intr.client
  -- reply to the interaction and make sure we should proceed with the operation
  if not intr:replyDeferred() then return end
  -- check whether the user has permissions to run this
  -- TODO: Implement members whitelist
  if intr.user ~= client.owner then
    intr:reply {
      embed = {
        description = 'Insufficient permissions: only the bot owner can run this.',
        title = FAIL_TITLE,
        color = FAIL_COLOR,
      }
    }
    return
  end

  client:info('cache-refresh: Refreshing cache...')
  stopwatch:reset()
  stopwatch:start()
  -- try refreshing the cache to the default branch
  local success, err = refresh()
  -- report failure
  if not success then
    client:error('cache-refresh: Failed to refresh the cache: ' .. err)
    intr:reply {
      embed = {
        description = err,
        title = FAIL_TITLE,
        color = FAIL_COLOR,
      }
    }
    stopwatch:stop()
    return
  end
  -- report success
  client:info('cache-refresh: Done in %s.\n', stopwatch:getTime():toString())
  intr:reply {
    embed = {
      title = SUCCESS_TITLE,
      color = CMD_COLOR,
    }
  }
  stopwatch:stop()

  docs.loadFromDir(configs.generate_docs_from)
  docs.saveJson(configs.docs_cache_path)
end

return {
  callback = callback,
  name = 'cache-refresh',
  description = 'Refreshes the cache updating it to the latest commit in the default branch.',
}
