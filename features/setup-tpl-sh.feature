Feature: Setup Template (sh); test fixtures for shell with YAML format

  Background:

    Given `tpl_vars` key 'env' '. ~/bin/.env.sh'
    Given the current commandpath

  Scenario: template to setup two files, one in a subdir, each with space in name

    Given 'tpl_vars' key 'env_setup' '$(env) && . \$CWD/tools/sh/init.sh && lib_load log std setup-sh-tpl && '
    Given temp dir 'setup-tpl-sh-feature-testdir-a'

    When the user runs `$(env_setup) setup_sh_tpl \$CWD/test/var/build-lib/setup-sh-tpl-1.sh setup_sh_tpl_`

    Then file 'File Name' lines equal:
    """
    Content

    Lines
    """
    And file 'Other Path/File Name' lines equal:
    """
    More stuff
    """

    Then clean temp. dir 'setup-tpl-sh-feature-testdir-a'


  Scenario: same but using dedicated Gherkin directive

    When 'setup-tpl-sh-feature-testdir-b' is setup from 'test/var/build-lib/setup-sh-tpl-1.sh' with setup_sh_tpl_

    Then file 'File Name' lines equal:
    """
    Content

    Lines
    """
    And file 'Other Path/File Name' lines equal:
    """
    More stuff
    """

    Then clean temp. dir 'setup-tpl-sh-feature-testdir-b'

