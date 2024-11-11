# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Tests for functions with non-trivial pipelines in the body

  Background: Set up database
    # TODO


  Scenario: Sort, Offset & Limit can be used in function bodies. Further, the results remains consistent across runs.
    # TODO


  Scenario: Reduce can be used in function bodies
    # TODO

  Scenario: A function may not have write stages in the body
    # TODO


  Scenario: A cycle cannot pass through a function with a reduce clause in its body
    # TODO


  Scenario: A cycle cannot pass through a function with a sort clause in its body
    # TODO: Or can it?

