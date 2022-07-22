local fs = require 'fs'
local exists, scandir = fs.existsSync, fs.scandirSync
local rm, rmdir = fs.unlinkSync, fs.rmdirSync

local join = require'pathjoin'.pathJoin

local configs = require 'configs'
local git = require 'git'

-- local branches -- lazy-loaded when needed

local repo_path = configs.repo_cache_path
local repo_url = configs.repo_url
local unsafe = configs.unsafe

local TMP_PATH = configs.repo_tmp_path
local GIT_DB = join(repo_path, '.git')

local cache = {}

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
  --
  -- handle tmp already existing
  if exists(TMP_PATH) then
    if unsafe then
      rmrf(TMP_PATH)
    else
      error(TMP_PATH .. ' directory already exists. Please either remove it or enable configs.unsafe')
    end
  end
  assert(fs.mkdirpSync(TMP_PATH))
  -- clone the repo into the temproray directory
  local success, err = git.clone(repo_url, TMP_PATH)
  if not success then
    rmrf(TMP_PATH)
    error(err)
  end
  -- handle the main directory already existing
  if exists(repo_path) then
    if unsafe then
      rmrf(repo_path)
    else
      error(repo_path .. ' directory already exists. Please either remove it or enable configs.unsafe')
    end
  end
  -- rename the temproray directory to `path`
  assert(fs.renameSync(TMP_PATH, repo_path))
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
  if not exists(repo_path) then
    return nil, 'No cache has been initalized at ' .. repo_path
  end
  -- make sure the path has a git database
  if not exists(GIT_DB) then
    return nil, 'The repository cache does not have a Git database'
  end
  -- start pulling any changes on the specified branch
  local success, err = git.pull(repo_path, branch)
  if not success then
    return nil, 'Git pull failed while refreshing the cache: ' .. err
  end
  return true
end

--- Deletes any cached data
function cache.remove()
  rmrf(configs.cache_path)
end

--- Check whether the repo cache exists or not.
---@return boolean
function cache.isInitialized()
  return exists(repo_path) and exists(GIT_DB)
end

return cache
