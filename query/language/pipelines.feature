# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL pipelines

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person owns ref @key,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age;
      entity company owns ref @key,
        plays employment:employer,
        owns name;
      relation friendship owns ref @key,
        relates friend;
      relation employment owns ref @key,
        relates employee,
        relates employer;
      attribute name @independent, value string;
      attribute age @independent, value integer;
      attribute ref value integer;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb


  Scenario: Matches can be chained, with variables bindings kept into later stages
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
    match
      $p has age $age;
    """
    Then uniquely identify answer concepts
      | p         | name            | age         |
      | key:ref:0 | attr:name:Alice | attr:age:10 |
      | key:ref:1 | attr:name:Bob   | attr:age:11 |


  Scenario: A match can be used to bind variables, and chained with an insert for constraints.
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
      | f         | p1        | p2        |
      | key:ref:3 | key:ref:0 | key:ref:1 |


  Scenario: The set of variables being streamed can be reduced using select.
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
      | p         |
      | key:ref:0 |


  Scenario: A match can be chained with a delete and insert to emulate an update.
    Given typeql write query
    """
    insert
      $p1 isa person, has name "Alice", has age 10, has ref 0;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    match
      $p1 isa person, has name "Alice", has age $age;
    delete
      has $age of $p1;
    insert
      $p1 has age 11;
    """
    Given transaction commits
    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name, has age $age;
    """
    Then uniquely identify answer concepts
      | p         | name            | age         |
      | key:ref:0 | attr:name:Alice | attr:age:11 |


  Scenario: A stream can be sorted
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
      | p         |
      | key:ref:0 |

    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name;
    sort $name desc;
    limit 1;
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:1 |


  Scenario: Sort, offset, limit can be combined
    Given typeql write query
    """
    insert
      $a0 isa age 0; $a1 isa age 1; $a2 isa age 2; $a3 isa age 3;
      $n0 isa name "Alice"; $n1 isa name "Bob"; $n2 isa name "Chris"; $n3 isa name "Dan";
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $age isa age; $name isa name;
    sort $age desc, $name;
    offset 5;
    limit 4;
    sort $name, $age;
    limit 2;
    """
    Then uniquely identify answer concepts
      | name            | age        |
      | attr:name:Alice | attr:age:1 |
      | attr:name:Bob   | attr:age:2 |


  Scenario: Reduce can be performed within groups
    Given typeql write query
    """
    insert
      $p0 isa person, has ref 0, has name "Alice", has age 11;
      $p1 isa person, has ref 1, has name "Alice", has age 12;
      $p2 isa person, has ref 2, has name "Bob", has age 23;
      $p3 isa person, has ref 3, has name "Bob", has age 24;
    """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
      $p isa person, has name $name, has age $age;
    reduce $sum_age = sum($age) groupby $name;
    """
    Then uniquely identify answer concepts
      | name            | sum_age          |
      | attr:name:Alice | value:integer:23 |
      | attr:name:Bob   | value:integer:47 |


  Scenario: Complex insert + delete migration with intersection of role names and attributes
    Given get answers of typeql write query
      """
      insert
        $u isa person, has name "Alex", has ref 0;
        $v isa person, has name "Bob", has ref 1;
        $w isa person, has name "Charlie", has ref 2;
        $x isa person, has name "Darius", has ref 3;
        $y isa person, has name "Alex", has ref 4;
        $z isa person, has name "Bob", has ref 5;
      """
    Given transaction commits
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity nameclass,
        owns name @key,
        plays naming:name;
      relation naming,
        relates named,
        relates name;
      person plays naming:named;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
        $att isa name;
      insert
        $x isa nameclass, has $att;
      """
    When typeql write query
      """
      match
        $p isa person, has name $n;
        $nc isa nameclass, has name $n;
      delete
        has $n of $p;
      insert
        (named: $p, name: $nc) isa naming;
      """
    Then transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $r isa naming (named: $p, name: $nc);
        $nc has name $n;
      """
    Then uniquely identify answer concepts
      | p         | n                 |
      | key:ref:0 | attr:name:Alex    |
      | key:ref:1 | attr:name:Bob     |
      | key:ref:2 | attr:name:Charlie |
      | key:ref:3 | attr:name:Darius  |
      | key:ref:4 | attr:name:Alex    |
      | key:ref:5 | attr:name:Bob     |

    When get answers of typeql read query
      """
      match
        $p isa person;
        $p has name $n;
      """
    Then answer size is: 0


  Scenario: Variables in modifier stages must be named
    Then typeql read query; fails with a message containing: "A non-anonymous variable is expected in this statement for the query"
      """
      match
        let $x = 5;
      reduce $sum = sum($x) groupby $_;
      """
    Then typeql read query; fails with a message containing: "A non-anonymous variable is expected in this statement for the query"
      """
      match
        let $x = 5;
      reduce $sum = sum($_) groupby $x;
      """
    Then typeql read query; fails with a message containing: "A non-anonymous variable is expected in this statement for the query"
      """
      match
        let $x = 5;
      select $_;
      """
    Then typeql read query; fails with a message containing: "A non-anonymous variable is expected in this statement for the query"
      """
      match
        let $x = 5;
      sort $_;
      """
