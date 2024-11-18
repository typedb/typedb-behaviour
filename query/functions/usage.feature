# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function call positions behaviour

  Background: Set up database
    Given TODO


  Scenario: Functions can be called in expressions.
    Given TODO


  Scenario: Functions can be called in comparators.
    Given TODO: On the left, right, or both-sides.


  Scenario: Functions can be called in `is` statements.
    Given TODO


  Scenario: repeated function calls within a query trigger execution from all pattern occurrences
    Given TODO: Something non-recursive


  Scenario: The same variable cannot be 'assigned' to twice, either by the same or different functions.
    Given TODO


  Scenario: Functions are stratified wrt negation
    Given TODO

  Scenario: Functions are stratified wrt aggregates
    Given TODO

  Scenario: A function being undefined must not be referenced by a separate function which is not being undefined.
    Given TODO

  Scenario: If a modification of a function causes a caller function to become invalid, the modification is blocked.
    Given TODO

  Scenario: If a modification of the schema causes a stored function to become invalid, the modification is blocked at commit itme
    Given TODO
