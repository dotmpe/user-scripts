[2018-08-24] Goal: shell history but better

# Req'ments
1. record shell scripts like a bookmark collection
2. auto-determine dependencies and prerequisite settings (static analysis)
3. record execution and context, track when/where/what has run per user (for
   some selected subset of scripts)
4. assemble CLI tools from collection subsets (ie. by prefix, metadata, host, etc.)
5. distribute collection using existing code VCS
6. code client in shell or compiled distributable, provide server with REST.
   Wrap it up by providing containerized dist.

# Progress
None. Initial orientation.

# See also
- [Composure], 7 basic shell functions to rule them all: draft, revise and
  others to create new functions from the last shell history and use the Bash
  AST to store metadata. Distribution using vanilla GIT.

- [commandlinefu.com], like the now-defunct [alias.sh], share snippets (public
  only) with an online community.

- [Explainshell], an online and now/almost [CLI] tool too for getting all the
  manpage bits for a given shell invocation or pipeline.


[Explainshell](https://explainshell.com)
[CLI](https://github.com/idank/explainshell/issues/4)
[commandlinefu.com](https://www.commandlinefu.com/commands/browse)
[Composure](https://github.com/erichs/composure)
