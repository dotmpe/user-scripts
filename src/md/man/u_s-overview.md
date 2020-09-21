% U-S(7) User-Scripts Manual: Overview | User-Scripts/0.1-alpha

Main user-guide manual for `User-Scripts` [U-s] or [Us] installations.

- The definite project documentation starts with the [README] which may not be
  included in the installation, 

TODO: rename to provide for user script as well? Use for dev/install now.
TODO: Run bin/user-box. Alias as `box`. See also +User-config/u-c helper.

## User Profile

Variable names for use in static env. Grouped.


LOG               Path, function- or command name to log-like.

                  XXX: Envs. can inherit LOG, but only file or command, or
                  always if U-s logger is imported.

PREFIX            Local basepath for installation, eg. `/usr/local` or
                  `~/.local`.

                  This variable should generally not be always set, unless the
                  scripts get carte-blanche to (try to) initialize subtrees and
                  install software there automatically.

SRC_PREFIX        Local basepath for keeping project checkouts or unpacked
                  distributions. This will be used by many others, and some
                  rules to avoid name collisions should be implemented but those
                  can't be prescribed here (on the value given with SRC_PREFIX).

                  The code checked out here should be used for building and
                  installation, but not become part of any installation. It
                  should be safe to delete the entire subdirectory, but in
                  non-production systems (ie. CI: dev and testing phases) a lot
                  will happen here including entire builds.

                  The above also means that the tree(s) may be reset to the
                  initial state any time.

                  XXX: To avoid complex setup, perhaps push to have one instance
                  per checkout
                  Or devise something on /src/local or /srv/src-local or
                  SRC_LOCAL or whatever; a subdir of Src-Prefix where copies
                  *are* allowed. Where subtrees are duples & variants of main
                  Src-Prefix.

                  Also; GIT cannot show several lines ('branches', 'tags')
                  at once, while SVN can. But SVN (afaicr) does subtree ceckouts
                  (better) also. But GIT can do reference checkouts.

VND_SRC_PREFIX    A basepath specifially for SCM checkouts, where each working
                  tree is two levels deep with the path indicating Group/Repo
                  names.

VND_GH_SRC        A basepath specifially for Git-Hub checkouts. If set it is
                  like VND_SRC_PREFIX but with the added assumptions:

                  - Group names are either GitHub user accounts or teams
                  - Repos names idem ditto
                  - the VND_GH_SRC directory may be neighbour to other domains,
                    and that basepath (one level up from VND_GH_SRC) can
                    be used for systems handling multiple domains.

                  Ie. this shell loop shows how the variables relate on a local
                  system:

                    for VND_SRC_PREFIX in $(dirname "$VND_GH_SRC")/*
                    do
                      test -d "$VND_SRC_PREFIX" || continue

                      true
                    done

SRV_PREFIX        TODO: static env for /srv. See @Service-Containers draft.

                  Variable data not sorted into *nix-y trees in general, but
                  grouped per volume, root dir names on volumes, and so on.

                  Those group-names are used in symlinks, and provided with a
                  suffix inherited from the volume that uniquely identifies
                  itself.
                  Iow. the suffix is equal to that of the target volume or group.

                  Currently this is the sub-Srv-Prefix name structure and suffix
                  parts:
                  ```
                    <group>-<disk-id>-<mount-id>
                  ```

                  So for example one `<group>`, we need a disk or other media
                  volume conventionally with a root-dir `<group>`. Although the
                  `<group>` may be on many other disks, each would get a unique
                  name with disk-Id and mount-Id under Srv-Prefix.

                  Here is the general setup (for a root-service),
                  'volume' group is the only one that leads out the Srv-Prefix.
                  ```
                    volume-<disk-id>-<mount-id>  -> <media-mount-point>
                    <group>-<disk-id>-<mount-id> -> volume-<disk-id>-<mount-id>/<group>
                  ```

                  So to recap, wolumes are usually disk paritions, but can be
                  cloud stores or other remote mounts.
                  Groups (dirs) can be any user-defined organisation, and
                  one could have nested groups that are similary symlinked.

                  An example of a setup:

                    /srv/mydata-1-1-example -> volume-1-1-example/My-Path-To-Data
                    /srv/volume-1-1-example -> /Volumes/USB-Disk
                    /srv/mydata-local -> mydata-1-1-example
                    /srv/volume-local -> volume-1-1-example

                  Instead of acessing `<mount-media-point>/<group>` directly,
                  there are two symlinks to resolve first with this setup.
                  And one more for every sub-group that is added.


## Features

Tested components or in development.
In alphabetical order.


### Docker
`u-s` uses a docker image for testing and or ad-hoc envs. See `u_s-dckr` and
related manuals.


### Service Contianers

To try to work to both canonical paths to file based data, and to provide
for host or even domain agnostic access.

- See Srv-Prefix under static env settings.
- The mount point usually is /mnt, or /Volumes on OSX.
- There is no data but symlink nodes under Srv-Prefix.

Eg. to allow host-agnostic access:

  <group>-local -> <group>-<disk-id>-<mount-id>

> XXX: may want to reintroduce dirs (iso flat-name) to manage large group
  collections but can't think of one way or the other useful, or without
  increasing the symlinks with a power. Also now all symlink targets are very
  simple relative paths except for the volume roots.

> XXX: this is there mostly for convenient implementation, after test/CI setup
  it may prove more efficient to resolve the target before creating the
  symlink; it should be possible to establish the group tree from that as
  well, but it simply req. for more sanity and validation in the setup.

To allow software to ignore the logical and physical location, it can use a
hardcoded symbolic path. And to do this host wide we simply set another alias,
but for the disk/mount-id part.

Only 'local' is used like that currently.

> TODO: I do wonder about symbol deref time when an app gets ie.
  ``/srv/my-important-sub-dir-local`` and needs to go over 4,5,6 or more
  readlinks per path access.

> XXX: currently the above is mostly true, but there is no rule specified that
  says these are identical or have the same target.
  ```
  /srv/mydata-local
  /srv/volume-local/mydata
  ```
  But they should.


[//]:             (Comment)
