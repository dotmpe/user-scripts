Feature: can use Gherking syntax to describe shell scripts

  Background: various setup functions can set `vars`, or `env` and other context attributes that may be output by either a "the user runs ..." or indirectly by another directive.

  Scenario: env runs
    When the user runs `true`
    Then `stdout` should be ""
    And `stderr` should be ""

  Scenario: setup temporary directory

    Given temp dir 'setup-tpl-sh-feature-testdir-a'
    When the user runs `printf %s $PWD`
    Then `stdout` should be "/tmp/setup-tpl-sh-feature-testdir-a"

    When the user runs 'pwd'
    Then `stdout` should be:
      """
      /tmp/setup-tpl-sh-feature-testdir-a

      """
