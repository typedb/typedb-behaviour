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
    entity person, owns ref @key, owns name;
    attribute name, value string;
    attribute ref, value integer;
    """
    Given transaction commits


  Scenario: Functions can be called in expressions.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer:
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      let $six = five() + 1;
    """
    Then uniquely identify answer concepts
      | six             |
      | value:integer:6 |
    Given transaction closes


  Scenario: Functions can be called in comparators.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer:
    match
      let $five = 5;
    return first $five;

    fun six() -> integer:
    match
      let $six = 6;
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
    fun five() -> integer:
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      let $ten = five() + five();
    """
    Then uniquely identify answer concepts
      | ten              |
      | value:integer:10 |
    Given transaction closes


  Scenario: The same variable cannot be 'assigned' to twice, either by the same or different functions.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun five() -> integer:
    match
      let $five = 5;
    return first $five;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails
    """
    match
      let $five = five();
      let $five = five();
    """


  Scenario: Assigning to an anonymous variable discards the returned value.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun nameof($person: person) -> { name }:
    match
      $person has name $name;
    return { $name };
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $_ isa person, has ref 0, has name "Jonathan";
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      $person isa person;
      let $_ = nameof($person);
    """
    Then uniquely identify answer concepts
      | person    |
      | key:ref:0 |
    Given transaction closes


  Scenario: Function arguments are passed properly according to index (typedb#7407)
    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
    """
    with
      fun subtract($y: integer, $x: integer) -> integer:
        match
          let $z = $y - $x;
        return first $z;

    match
      # Declare $y before $x
      let $y = 1;
      let $x = 2;
       # Pass $x before $y
      let $z = subtract($x, $y);
    """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x               | y               | z               |
      | value:integer:2 | value:integer:1 | value:integer:1 |


  Scenario: A variable that is input from a previous stage may not be assigned to
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert $p isa person, has name "John", has ref 0;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'name' may not be assigned to, as it was already bound in a previous stage"
    """
      with
        fun name_of($p: person) -> { name }:
        match $p has name $name;
        return { $name };


      match
        $p isa person, has name $name;
      match
        let $name = name_of($p);
      """
