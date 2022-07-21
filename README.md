A Discord bot with the goal of serving the latest Discordia wiki with slash commands.

The documentation is generated from Discordia code directly, and supports auto-cloning and auto-pulling for new changes in the source-code.

## Install & Dependencies

There are four direct dependencies for this bot:
1. [SinisterRectus/Discordia](https://github.com/SinisterRectus/Discordia).
2. [Bilal2453/discordia-interactions](https://github.com/Bilal2453/discordia-interactions/). (Listed in this repo as a Git submodule. Only available through Git)
3. [creationix/coro-spawn](https://luvit.io/lit.html#coro-spawn).
4. [git](https://git-scm.com/). (Through the CLI)


To install this bot, simply execute: `git clone --recursive git@github.com:Bilal2453/discordia-wiki-bot.git`.

A new folder with the name `discordia-wiki-bot` will show up in the directory the command was executed inside.

First thing you want to do before running the bot is changing the `token` field inside `configs.lua` to your own bot's token.

You should now be ready to run the command. Make sure the bot application has the required scopes, `bot` and `application.commands` that is.


## Available commands

In the following usage list, `<argument>` indicates a required argument, `[argument]` indicats an optional one.

`[target]` is (whenever implied to be acceptable) an optional user to be mentioned in the bot's reply.

Currently the bot has the following slash commands:

`/cache-refresh`: This is an owner only command. Re-sync the commands to the latest configured branch, and re-generates the documentation.

`/class <class_name> [target]`: Sends the documentation of a specific class, the class name is required and case-insensitive. `target` is an optional user to mention in the reply.

`/method <class_name> <method_name> [target]`: Sends the documentation of `class_name.method_name`, where `method_name` is the name of the method and `class_name` is the class containing it.

`/property <class_name> <property_name> [target]`: Sends the documentation of `class_name.property_name`, where `property_name` is a property under `class_name`.

`/wiki <query> [target]`: Sends the documentation for a search query `query`. The query can be of many formats, for example: `class[%p]method`, `class[%p]property`, `class`, `method`, `property`.
`%p` indicates any punctuations, so for example `class#method`, `class>property` are all acceptable.
If the query can resolve to multiple results, only the first to match result is sent.


## Configs

Under the root tree, you will find `configs.lua`. This is where all of the available configurations can be altered. Available fields are:

- `token`: The bot token. Should be prefixed with `Bot `, directly passed to `client.run`.
- `client_options`: A table of client options. Directly passed to the client constructor.
- `docs_cache_path`: The path at which a JSON file is created, to cache the generated docs. Default: `./cache/docs.json`.
- `repo_cache_path`: The path to which the Git repo is cloned. Default: `./cache/discordia`.
- `generate_docs_from`: The path from which to feed the Lua files to the doc generator. Default `./cache/discordia/libs`.
- `repo_url`: The Git URL to use to clone the repo. Default: `https://github.com/SinisterRectus/discordia.git`.
- `wiki_base`: The base URL under which the wiki exists. Default `https://github.com/SinisterRectus/Discordia/wiki/`. Note: You always want a `/` (slash) at the end of the URL.
- `unsafe`: Whether things under `repo_cache_path` and `{repo_cache_path}/../.tmp` can be automatically deleted or not. I recommend to turn this option on. Default: `false`.
- `git_binary`: The path or executable name used to spawn Git CLI. Default: `git`.
- `branch`: The branch to clone and sync against. This is what the docs will be generated from. Default: `master`.
- `detach`: Allows `git.clone` to enter detach state. This is a state where the clone tree does not point to any branch, rather it points to a specific point in time (in history). I have not tested this, and it is not recommended. Only works on initial clones. Default: `false`. 
- `detach_to`: If `detach` is true, clone from this branch instead of `"origin/" .. branch`.
- `reset_to`: Instead of pulling from `branch` on `git.pull` and `/cache-refresh`, instead pull from this branch. Not recommended. Default: `false`.

## License

All files under this repo are licensed under the Apache 2.0 License, excluding dependencies. See [[LICENSE]] for more information.
Pull Requests are welcomed, preferably discuss the desired changes with me first, either using GitHub issues or on my Discord.
