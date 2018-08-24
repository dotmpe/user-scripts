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
None. [Initial orientation](doc/dev/main.md).

# See also
- [Composure][1], 7 basic shell functions to rule them all: draft, revise and
  others to create new functions from the last shell history and use the Bash
  AST to store metadata. Distribution using vanilla GIT.

- [commandlinefu.com][2], like the now-defunct [alias.sh][3], share snippets
  (public only) with an online community.

- [Explainshell][4], an online and now/almost [CLI][5] tool too for getting all
  the manpage bits for a given shell invocation or pipeline.


[1]: https://github.com/erichs/composure
[2]: https://www.commandlinefu.com/commands/browse
[3]: http://web.archive.org/web/*/alias.sh
[4]: https://explainshell.com
[5]: https://github.com/idank/explainshell/issues/4

