# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL pipelines

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define
      entity person owns ref @key,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age @card(0..);
      entity company owns ref @key,
        plays employment:employer,
        owns name;
      relation friendship owns ref @key,
        relates friend;
      relation employment owns ref @key,
        relates employee,
        relates employer;
      attribute name value string;
      attribute age value long;
      attribute ref value long;
      """
    Given transaction commits


  Scenario: Matches can be chained, with variables bindings kept into later stages
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has name "Alice", has age 10, has ref 0;
      $p2 isa person, has name "Bob", has age 11, has ref 1;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name;
      $p has age $age;
    """
    Then uniquely identify answer concepts
      | p         | name            | age          |
      | key:ref:0 | attr:name:Alice | attr:age:10  |
      | key:ref:1 | attr:name:Bob   | attr:age:11  |


  Scenario: A match can be used to bind variables, and chained with an insert for constraints.
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has name "Alice", has age 10, has ref 0;
      $p2 isa person, has name "Bob", has age 11, has ref 1;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
    """
    match
      $p1 isa person, has name "Alice";
      $p2 isa person, has name "Bob";
    insert
      $f isa friendship, links (friend: $p1, friend: $p2), has ref 3;
    """
    Then uniquely identify answer concepts
      | f         | p1              | p2           |
      | key:ref:3 | key:ref:0       | key:ref:1    |


  Scenario: The set of variables being streamed can be reduced using select.
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has name "Alice", has age 10, has ref 0;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p isa person, has name "Alice";
    select $p;
    """
    Then uniquely identify answer concepts
      | p              |
      | key:ref:0      |


  Scenario: A stream can be sorted on a set of variables
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has name "Alice", has age 10, has ref 0;
      $p2 isa person, has name "Bob", has age 11, has ref 1;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name;
    sort $name;
    limit 1;
    """
    Then uniquely identify answer concepts
      | p              |
      | key:ref:0      |

    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name;
    sort $name desc;
    limit 1;
    """
    Then uniquely identify answer concepts
      | p              |
      | key:ref:1      |


  Scenario: Sort, offset, limit can be combined
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has age 0, has age 1, has age 2, has age 3, has ref 0;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p1 isa person, has age $age;
    sort $age;
    offset 2;
    limit 1;
    """
    Then uniquely identify answer concepts
      | age             |
      | attr:age:2      |

    Given get answers of typeql read query
    """
    match
      $p1 isa person, has age $age;
    sort $age desc;
    offset 2;
    limit 2;
    """
    Then uniquely identify answer concepts
      | age             |
      | attr:age:1      |
      | attr:age:0      |