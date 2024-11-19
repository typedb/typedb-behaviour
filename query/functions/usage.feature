# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function call positions behaviour

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    entity person, owns name;
    attribute name, value string;
    """
    Given transaction commits


  Scenario: Functions can be called in expressions.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      $six = five() + 1;
    """
    Then uniquely identify answer concepts
      | six          |
      | value:long:6 |
    Given transaction closes


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
