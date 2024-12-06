# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function Usage

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
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> long :
    match
      $five = 5;
    return first $five;

    fun six() -> long :
    match
      $six = 6;
    return first $six;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      five() < 6;
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      5 < six();
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      five() < six();
    """
    Then answer size is: 1
    When get answers of typeql read query
    """
    match
      five() > six();
    """
    Then answer size is: 0


  Scenario: repeated function calls within a query trigger execution from all pattern occurrences
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
      $ten = five() + five();
    """
    Then uniquely identify answer concepts
      | ten           |
      | value:long:10 |
    Given transaction closes


  Scenario: The same variable cannot be 'assigned' to twice, either by the same or different functions.
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
    When typeql read query; fails
    """
    match
      $five = five();
      $five = five();
    """

