return {
  token = 'Bot ',
  client_options = nil,

  cache_path      = './cache/',  -- the directory under which all cache related stuff are stored.
  docs_cache_path = 'docs.json', -- the folder under which json dumps of the classes are saved to. Final path is `configs.cache_path .. configs.docs_cache_path'.
  repo_cache_path = 'discordia', -- the folder under which the repo is cloned and cached. Final path is `configs.cache_path .. configs.repo_cache_path'.
  repo_tmp_path   = '.tmp',      -- the folder under which the repo is initially cloned. Final path is `configs.cache_path .. configs.repo_tmp_path`.

  generate_docs_from = './cache/discordia/libs', -- the folder which is scanned for Lua files to be fed to the docgen parser.
  repo_url = 'https://github.com/SinisterRectus/discordia.git', -- any git compatible URL to sync against.
  unsafe = false,     -- when true will allow `cache.initialize` to automatically delete cache and tmp directories instead of erroring.

  git_binary = 'git', -- the path to the git executable. can be simply `git` if installed in PATH.
  branch = 'master',  -- the default branch to sync against.
  detach = false,     -- detach the repo once cloned to configs.detach_to or to origin/branch
  reset_to = nil,     -- on each git.pull a hard reset is done to apply the fetched data. by default this is origin/branch.
  detach_to = nil,    -- if detach is true and this is unset, defaults to origin/branch

  wiki_base = 'https://github.com/SinisterRectus/Discordia/wiki/', -- the base URL of the Wiki to suffix class names to.

  -- A unique color for each type of response
  res_colors = {
    class = 0xaaaaee,
    method = 0x12b1b1,
    property = 0xdf5555,
  },

  refresh_allowed_users = {}, -- A map <string, truthy> of the User's IDs allowed to use cache-refresh command
  refresh_allowed_roles = {}, -- A map <string, thuthy> of the Role's IDs allowed to use cache-refresh command 
}
