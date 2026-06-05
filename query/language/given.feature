# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Given Clause

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


  Scenario: raw values can be used in given rows
    Given connection open read transaction for database: typedb
    Given query is given rows
      | n: string         |
      | value:string:Jane |

    When get answers of typeql read query with given rows
      """
      given $n: string;
      match $p isa person, has name == $n;
      """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:101 |


  Scenario: concepts can be used in given rows
    Given connection open read transaction for database: typedb
    Given query is given rows
      | p: person      |
      | iid:entity:0:1 |
    When get answers of typeql read query with given rows
      """
      given $p: person;
      match $p has name $n;
      """
    Then uniquely identify answer concepts
      | n              |
      | attr:name:Jane |


  Scenario: Variables in given rows cannot be reassigned to
    Given connection open read transaction for database: typedb
    Given query is given rows
      | x               |
      | value:integer:5 |
    Then typeql read query with given rows; fails with a message containing: "The variable 'x' may not be assigned to, as it was already bound in a previous stage"
      """
      given $x: integer;
      match let $x = 6;
      """


  Scenario: Given rows may contain multiple rows
    Given connection open read transaction for database: typedb
    Given query is given rows
      | x               |
      | value:integer:3 |
      | value:integer:5 |
      | value:integer:7 |
    When get answers of typeql read query with given rows
      """
      given $x: integer;
      match let $y = 2 * $x;
      """
    Then uniquely identify answer concepts
      | y                 |
      | value:integer: 6  |
      | value:integer: 10 |
      | value:integer: 14 |


  Scenario: Given rows are checked against declared types
    Given connection open read transaction for database: typedb
    # Values: Pass a string instead
    Given query is given rows
      | x                |
      | value:integer:3  |
      | value:string:abc |
    Then typeql read query with given rows; fails with a message containing: "The given value at row '1' and column '0' does not not satisfy the declared type"
      """
      given $x: integer;
      match let $y = 2 * $x;
      """

    # Concepts: Pass a person (John) instead
    Given query is given rows
      | comp           |
      | iid:entity:0:0 |
    Then typeql read query with given rows; fails with a message containing: "The given value at row '0' and column '0' does not not satisfy the declared type"
      """
      given $comp: company;
      match $comp has name $name;
      """


  Scenario: Variables which are provided in the given row but not declared are flagged.
    Given connection open read transaction for database: typedb
    Given query is given rows
      | x               | z               |
      | value:integer:5 | value:integer:6 |
    Then typeql read query with given rows; fails with a message containing: "The variable 'z' was not declared in the query"
      """
      given $x: integer, $y: integer?;
      match try { let $p = $x + $y; };
      """


  Scenario: Concepts in given rows are validated to exist
    Given connection open read transaction for database: typedb

    Given query is given rows
      | person         |
      | iid:entity:0:0 |
    When get answers of typeql read query with given rows
      """
      given $person: person;
      select $person;
      """
    Then uniquely identify answer concepts
      | person      |
      | key:ref:100 |

    Given query is given rows
      | person           |
      | iid:entity:0:123 |
    Then typeql read query with given rows; fails with a message containing: "The given instance at row '0' and column '0' does not exist in the database"
      """
      given $person: person;
      select $person;
      """


  Scenario: Given entries can be used in write stages
    Given connection open write transaction for database: typedb
    Given query is given rows
      | name               |
      | value:string:James |
    When get answers of typeql write query with given rows
      """
      given $name: string;
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


  Scenario: concepts given can be subtypes of the declared types
    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
      attribute weight, value integer;
      entity animal, owns weight;
      person sub animal;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given query is given rows
      | p: animal      |
      | iid:entity:0:1 |
    When get answers of typeql write query with given rows
        """
        given $p: animal;
        insert $p has weight 65;
        """
    When get answers of typeql read query
      """
      match $p isa person, has name $name, has weight $weight;
      """
    Then uniquely identify answer concepts
      | p           | name           | weight        |
      | key:ref:101 |attr:name:Jane | attr:weight:65 |
    Given transaction commits

    # Bonus, ensure the bounds are tight.
    Given connection open write transaction for database: typedb
    Given query is given rows
      | p: animal      |
      | iid:entity:0:1 |
    # Fail, Animal does not own age.
    When typeql write query with given rows; fails with a message containing: "Left type 'animal' across constraint 'has' is not compatible with right type 'age'"
        """
        given $p: animal;
        insert $p has age 12;
        """


  Scenario: Given row entries can be optional
    # Undeclared None fail at runtime
    Given connection open write transaction for database: typedb
    Given query is given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    Then typeql write query with given rows; fails with a message containing: "The given value at row '1' and column '1' was None, but the variable was not declared optional"
        """
        given $ref: integer, $name: string;
        insert $p isa person, has ref == $ref, has name == $name;
        """

    # Declared None, used outside try
    Given connection open write transaction for database: typedb
    Given query is given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    Then typeql write query with given rows; fails with a message containing: "A write stage uses the optional variable 'name' outside a 'try' block"
        """
        given $ref: integer, $name: string?;
        insert $p isa person, has ref == $ref, has name == $name;
        """

    # normal
    Given connection open write transaction for database: typedb
    Given query is given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
        """
        match $p isa person, has name "James";
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:110 |
    When get answers of typeql read query
        """
        match $p isa person; not { $p has name $name; };
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:111 |

  Scenario: The order of variables in the given rows does not matter, omitted ones are treated as optional, undeclared ones are flagged.
    Given connection open write transaction for database: typedb
    Given query is given rows
      | name               | ref               |
      | value:string:James | value:integer:110 |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """
    Given query is given rows
      | ref               |
      | value:integer:111 |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """

    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
        """
        match $p isa person, has name "James";
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:110 |
    When get answers of typeql read query
        """
        match $p isa person; not { $p has name $name; };
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:111 |
