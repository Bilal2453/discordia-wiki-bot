return {
  token = 'Bot ',
  client_options = nil,

  docs_cache_path = './cache/docs.json', -- the folder under which json dumps of the classes are saved to,
  repo_cache_path = './cache/discordia', -- the folder under which the repo is cloned and cached.
  generate_docs_from = './cache/discordia/libs', -- the folder which is scanned for Lua files to be fed to the docgen parser.
  repo_url = 'https://github.com/SinisterRectus/discordia.git', -- any git compatible URL to sync against.
  unsafe = false,     -- when true will allow `cache.initialize` to automatically delete cache and tmp directories instead of erroring.

  git_binary = 'git', -- the path to the git executable. can be simply `git` if installed in PATH.
  branch = 'master',  -- the default branch to sync against.
  detach = false,     -- detach the repo once cloned to configs.detach_to or to origin/branch
  detach_to = nil,    -- if detach is true and this is unset, defaults to origin/branch
  reset_to = nil,     -- on each git.pull a hard reset is done to apply the fetched data. by default this is origin/branch.

  wiki_base = 'https://github.com/SinisterRectus/Discordia/wiki/', -- the base URL of the Wiki to suffix class names to.

  -- A unique color for each type of response
  res_colors = {
    class = 0xaaaaee,
    method = 0x12b1b1,
    property = 0xdf5555,
  }
}
