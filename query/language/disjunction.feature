# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Disjunction

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


  Scenario: disjunctions return the union of composing query statements
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa company, has name "Amazon", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa $t; { $t label person; } or { $t label company; };
      """
    Then uniquely identify answer concepts
      | x         | t             |
      | key:ref:0 | label:person  |
      | key:ref:1 | label:company |
    When get answers of typeql read query
      """
      match $x isa $_; { $x has name "Jeff"; } or { $x has name "Amazon"; };
      """
    Then uniquely identify answer concepts
      | x         |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: disjunctions with no answers
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa $t; { $t label person; } or { $t label company; };
      """
    Then answer size is: 0


  Scenario: a variable reused across all branches is returned
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $first isa person, has ref 0;
        $second isa person, has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match { $person isa person, has ref 0; } or { $person isa person, has ref 1; };
      """
    Then uniquely identify answer concepts
      | person    |
      | key:ref:0 |
      | key:ref:1 |


  Scenario: a variable reused across all nested branches of a nested disjunction is returned
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $p1 isa person, has ref 10, has name "Alice";
        $p2 isa person, has ref 11, has name "Bob";
        $p3 isa person, has ref 12, has name "Charlie";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match 
      {
        { $p has ref 10; } or { $p has ref 11; };
      } or {
        { $p has ref 11; } or { $p has ref 12; };
      };
      """
    Then uniquely identify answer concepts
      | p          |
      | key:ref:10 |
      | key:ref:11 |
      | key:ref:12 |


  Scenario: a variable only used in one branch is not returned
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $p1 isa person, has ref 1, has name "Dave";
        $p2 isa person, has ref 2, has name "Eve";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match 
      { $p isa person, has ref 1; $other isa person, has ref 2; } or { $p isa person, has ref 2; };
      """
    Then answers do not contain variable: other
    Then uniquely identify answer concepts
      | p         |
      | key:ref:1 |
      | key:ref:2 |


  Scenario: a conjunction where one disjunction produces a variable, and the other only references it can be planned.
    Given transaction closes
    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match
    not {
      { $e isa person; } or { $e isa company; };
      { $e has $n; } or { $t sub $s; };
    };
    """
    Then answer size is: 1


  Scenario: a disjunction that both binds and consumes a variable can be planned
    Given typeql write query
      """
      insert
        $_ isa person, has ref 0;
        $_ isa person, has ref 1;
        $_ isa person, has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Then get answers of typeql read query
      """
      with fun refof($x:person) -> { ref }: match $x isa person; $_ has ref $ref; return { $ref };
      match $x has ref $ref; { let $b = $ref; } or { let $ref in refof($x); };
      """
    Then uniquely identify answer concepts
      | x         | ref        |
      | key:ref:0 | attr:ref:0 |
      | key:ref:1 | attr:ref:1 |
      | key:ref:2 | attr:ref:2 |


