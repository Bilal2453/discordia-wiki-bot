local fs = require 'fs'
local exists = fs.existsSync

local configs = require 'configs'
local spawn = require 'coro-spawn'
local dump = require 'pretty-print'.dump

local git = {}

--- A helper function to spawn the Git binary and await its exit, with error handling.
---@param options table
---@param await? boolean # default `true`.
---@return table|nil process_or_nil
---@return string|nil err
local function spawnGit(options, await)
  await = await == nil and true or await
  -- spawn git with the supplied options
  local process, err = spawn(configs.git_binary, options or {})
  if not process then
    return nil, err
  end
  -- yield current coroutine until process exit
  if await then
    local code, sig = process.waitExit()
    if code ~= 0 then
      return nil, ('Git exited with non-zero code (code %i , signal %i) with options: %s: %s')
        :format(code, sig, dump(options, false, true), process.stderr.read())
    end
  end
  return process
end

--- Clones a Git repository with `url` into `dir`.
--- Returns `nil, err` on failure.
---@param url string  # will raise an error if not supplied.
---@param dir? string # default `configs.docs_cache_path`.
---@return boolean|nil success, table|string process_or_err
function git.clone(url, dir)
  assert(url, 'bad argument #1 to git.clone (expected string, got ' .. type(url) .. ')')
  dir = dir or configs.repo_cache_path
  -- does the specified directory exists?
  do
    local exist, err = exists(dir)
    if not exist then
      return nil, err or 'unknown'
    end
  end
  -- start the cloning
  local process, err = spawnGit {
    stdio = {true, true, true},
    args = {'clone', '--no-tags', url, dir},
  }
  if not process then
    return nil, err or 'unknown'
  end
  -- check out a default branch
  local branch = configs.detach and (configs.detach_to or ('origin/' .. configs.branch)) or configs.branch
  spawnGit {
    stdio = {true, true, true}, -- TODO: do we need stdio here
    args = {'-C', dir, 'checkout', branch},
  }
  return true, process
end

--- Syncs the repository located under `dir` to remote.
--- Returns `nil, err` on failure.
---@param repo_path string # raises an error if not supplied.
---@param branch? string # Pull from a specific branch
---@return boolean|nil success, table|string process_or_err
function git.pull(repo_path, branch)
  assert(repo_path, 'bad argument #1 to git.pull (expected string, got ' .. type(repo_path) .. ')')
  branch = branch or configs.reset_to or ('origin/' .. configs.branch)

  -- does the specified directory exists?
  do
    local exist, err = exists(repo_path)
    if not exist then
      return nil, err or 'unknown'
    end
  end
  -- start fetching new changes
  local process, err = spawnGit {
    stdio = {true, true, true},
    args = {'-C', repo_path, 'fetch', '--all', '--no-tags', '--force', '--prune'},
  }
  if not process then
    return nil, err or 'unknown'
  end

  -- after fetching, hard reset current branch to origin/branch
  process, err = spawnGit {
    stdio = {true, true, true},
    args = {'-C', repo_path, 'reset', '--hard', branch}
  }
  if not process then
    return nil, err or 'unknown'
  end
  return true, process
end

return git
