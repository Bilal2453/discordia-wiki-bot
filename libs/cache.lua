local fs = require 'fs'
local exists, scandir = fs.existsSync, fs.scandirSync
local rm, rmdir = fs.unlinkSync, fs.rmdirSync

local join = require'pathjoin'.pathJoin

local configs = require 'configs'
local git = require 'git'

local TMP_PATH = '../.tmp'
local GIT_DB = '.git'
local branches -- lazy-loaded when needed

local cache = {
  --- The path at which the repo should be cached.
  ---@type string
  path = configs.repo_cache_path,
  --- The URL of the Git repo to sync against.
  ---@type string
  repo_url = configs.repo_url,
  --- Toggling this on, will allow the `cache.initialize` to automatically delete cache and tmp directories.
  --- Should be safe as long as the user is not also writing data there.
  ---@type boolean
  unsafe = configs.unsafe,
}

--- A helper function to recursively delete a directory.
--- See coro-fs for the inspiration.
---@param dir string
---@return boolean|nil success, string? err_msg
local function rmrf(dir)
  local success, err = rmdir(dir)
  if success then return success end

  err = err or ''
  if err:match("^ENOTDIR:") then return rm(dir) end
  if not err:match("^ENOTEMPTY:") then return success, err end

  for entry, kind in assert(scandir(dir)) do
    local subPath = join(dir, entry)
    if kind == 'directory' then
      success, err = rmrf(join(dir, entry))
    else
      success, err = rm(subPath)
    end
    if not success then return success, err end
  end
  return rmdir(dir)
end

--- Initializes the cache by Git cloning the repo. If the repo already exists, this will fail.
function cache.initialize()
  -- make a new temproray directory
  -- we clone first into a temproray directory to ensure integrity
  -- it also ensures the async code is not going to try indexing a cache path that does not exists while cloning
  local tmp = join(cache.path, TMP_PATH)
  -- handle tmp already existing
  if exists(tmp) then
    if cache.unsafe then
      rmrf(tmp)
    else
      error(tmp .. ' directory already exists. Please either remove it or enable configs.unsafe')
    end
  end
  assert(fs.mkdirpSync(tmp))
  -- clone the repo into the temproray directory
  local success, err = git.clone(cache.repo_url, tmp)
  if not success then
    rmrf(tmp)
    error(err)
  end
  -- handle the main directory already existing
  if exists(cache.path) then
    if cache.unsafe then
      rmrf(cache.path)
    else
      error(cache.path .. ' directory already exists. Please either remove it or enable configs.unsafe')
    end
  end
  -- rename the temproray directory to `path`
  assert(fs.renameSync(tmp, cache.path))
end

--- Refreshes the cache syncing it with most recent changes on branch.
---@param branch? string
---@return boolean|nil success, string|nil err
function cache.refresh(branch)
  branch = branch or configs.branch

  -- validate the branch input
  --[[
  if not branches then
    try fetching the branches using `git branch`
    local err; branches, err = git.branches()
    if not branches then
      return nil, 'Failed to fetch the available branches: ' .. err
    end
    also make an array of the map, used for reporting
    for k in pairs(branches) do
      branches[#branches+1] = k
    end
  end
  -- validate that the input branch does indeed exists
  if branch ~= nil and not branches[branch] then
    return nil, 'No such branch "' .. branch .. '"\nAvailable branches are: ' .. table.concat(branches, ', ')
  end
  ]]

  -- make sure the path exists
  if not exists(cache.path) then
    return nil, 'No cache has been initalized at ' .. cache.path
  end
  -- make sure the path has a git database
  if not exists(join(cache.path, GIT_DB)) then
    return nil, 'The repository cache does not have a Git database'
  end
  -- start pulling any changes on the specified branch
  local success, err = git.pull(cache.path, branch)
  if not success then
    return nil, 'Git pull failed while refreshing the cache: ' .. err
  end
  return true
end

--- Deletes any cached data
function cache.remove()
  -- remove the repo cache
  rmrf(cache.path)
  -- remove any temproray cache
  rmrf(join(cache.path, TMP_PATH))
  rm(configs.docs_cache_path)
end

--- Check whether the repo cache exists or not.
---@return boolean
function cache.isInitialized()
  return exists(cache.path) and exists(join(cache.path, GIT_DB))
end

return cache
