# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Inputs Clause

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb

    Given connection open schema transaction for database: typedb
    # Do first to guarantee numbering
    Given typeql schema query
      """
      define
        entity person;
        attribute age, value integer;
      """
    Given typeql schema query
      """
      define
        person
          plays employment:employee,
          owns name @card(0..),
          owns age @card(0..),
          owns ref @key;
        entity company
          plays employment:employer,
          owns name @card(0..),
          owns ref @key;
        relation employment
          relates employee @card(0..),
          relates employer @card(0..),
          owns ref @key;
        attribute name value string;
        attribute ref value integer;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      # Use separate stages to guarantee numbering.
      insert $_ isa person, has name "John", has age 25, has ref 100;
      insert $_ isa person, has name "Jane", has age 30, has ref 101;
      insert $_ isa company, has name "TypeDB", has ref 200;
      """
    Given transaction commits


    Scenario: raw values can be used as inputs
      Given connection open read transaction for database: typedb
      Given query inputs
        | n: string         |
        | value:string:Jane |

      When get answers of typeql read query with inputs
        """
        inputs $n: string;
        match $p isa person, has name == $n;
        """
      Then uniquely identify answer concepts
        | p           |
        | key:ref:101 |


    Scenario: concepts can be used as inputs
      Given connection open read transaction for database: typedb
      Given query inputs
        | p: person      |
        | iid:entity:0:1 |
      When get answers of typeql read query with inputs
        """
        inputs $p: person;
        match $p has name $n;
        """
      Then uniquely identify answer concepts
        | n              |
        | attr:name:Jane |


  Scenario: input variables cannot be reassigned to
    Given connection open read transaction for database: typedb
    Given query inputs
      | x               |
      | value:integer:5 |
    Then typeql read query with inputs; fails with a message containing: "The variable 'x' may not be assigned to, as it was already bound in a previous stage"
      """
      inputs $x: integer;
      match let $x = 6;
      """


  Scenario: Inputs may contain multiple rows
    Given connection open read transaction for database: typedb
    Given query inputs
      | x               |
      | value:integer:3 |
      | value:integer:5 |
      | value:integer:7 |
    When get answers of typeql read query with inputs
      """
      inputs $x: integer;
      match let $y = 2 * $x;
      """
    Then uniquely identify answer concepts
      | y                 |
      | value:integer: 6  |
      | value:integer: 10 |
      | value:integer: 14 |


  Scenario: Input rows are checked against declared types
    Given connection open read transaction for database: typedb
    # Values: Pass a string instead
    Given query inputs
      | x                |
      | value:integer:3  |
      | value:string:abc |
    Then typeql read query with inputs; fails with a message containing: "The input value for variable 'x' at row index '1' did not satisfy the declared type 'integer'"
      """
      inputs $x: integer;
      match let $y = 2 * $x;
      """

    # Concepts: Pass a person (John) instead
    Given query inputs
      | comp           |
      | iid:entity:0:0 |
    Then typeql read query with inputs; fails with a message containing: "The input value for variable 'comp' at row index '0' did not satisfy the declared type 'company'"
      """
      inputs $comp: company;
      match $comp has name $name;
      """


  Scenario: Concepts in input rows are validated to exist
    Given connection open read transaction for database: typedb

    Given query inputs
      | person         |
      | iid:entity:0:0 |
    When get answers of typeql read query with inputs
      """
      inputs $person: person;
      select $person;
      """
    Then uniquely identify answer concepts
      | person      |
      | key:ref:100 |

    Given query inputs
      | person           |
      | iid:entity:0:123 |
    Then typeql read query with inputs; fails with a message containing: "The input instance for variable 'person' at row '0' was not found in the database"
      """
      inputs $person: person;
      select $person;
      """


    Scenario: Inputs can be used in write stages
      Given connection open write transaction for database: typedb
      Given query inputs
        | name               |
        | value:string:James |
      When get answers of typeql write query with inputs
        """
        inputs $name: string;
        insert $_ isa person, has name == $name, has ref 110;
        """
      Then transaction commits

      Given connection open read transaction for database: typedb
      When get answers of typeql read query
        """
        match $p isa person, has name $name;
        """
      Then uniquely identify answer concepts
        | p           | name            |
        | key:ref:100 | attr:name:John  |
        | key:ref:101 | attr:name:Jane  |
        | key:ref:110 | attr:name:James |


  # TODO: Test accepting subtypes as input
