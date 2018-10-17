# Continuous Integration

Current CI scripts run checks and tests.
No reports, but stdout/err log.

## Background
CI scripts should be used before commit, but a local environment will not
be able to check for all contingencies. Or often be able to complete within
reasonable time; running a full test on non-trivial projects will impede
development flow.

So we both need to be able to select specific tests, and accurately group tests.

At the lowest level, the unit tests purely test our code. These try to isolate,
and check for all states of a specific function or other coded scope.
As a rule of thumb unit tests should:

- not connect to services
- not use the network
- not even access a file

This allows them to be quick, and to focus on function. With the proper tools
it should be able to mock all off the above. Tests may run natively. And with or
without some level of transpiled feature or specification syntax.

Which abstract our tests further iot. isolate state.

Or tools to provide for 
services for mocking and
test-data providers.
test can be coded

Without indirectly testing other components or context variables.

Beyond unit testing and its code coverage, another easy test is just to check
wether a certain stack runs in some environment. System and integration testing,
even acceptance testing are domains where automation and scripting can come in.

Then there are
are separate
there are other domains of testing and checks: delinting

Other domains of testing are performance analysis, and static security audits or
pentest setups.

Some prior abstraction of the context is required.

## Build matrix

Travis supports matrix of any dimensions (200 jobs max), varying language
version and env for most job types. Some languages have more dimension types,
ie. jdk and rvm for Ruby.

Each item listed under the ``env`` attribute adds combination to the build.
To set global variables, a declaration can be put in a step block. Ie. in the
``before_install`` to set it before all other scripts, but splitting to
``env.global`` (and ``env.matrix`` for all build-env combinations) helps to keep
the script clean of profile data.

Env should not hold large list of settings, but organize those into profile
scripts. Use ``env.{global,matrix}`` to set key parameters. Having one well
defined name, Id, or other specifier or description is better than a big list
of misc. key/values.

Travis is the only build atm. so no need for further comment.

## Script env

Writing shell scripts is always an uncertain affair.


## Skipping CI builds

Include a skip tag in the commit, either
```
[<KEYWORD> skip]
[skip <KEYWORD>]
```

where <KEYWORD> can be ci, travis, travis ci, travis-ci, or travisci


(https://docs.travis-ci.com/user/customizing-the-build/)
