# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Optional

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

  # TODO: Pipelined writes
  # Feature: insert, delete, put, and update clauses can contain optionals
  # Feature: write clauses operating with all optional variables populated execute as expected
  # Feature: write clauses operating against any empty optional variables do nothing
  # Feature: write clauses cannot contain nested optionals

  # TODO: pipelines
  # Feature: an optionally

  Scenario: a matching optional returns all variables from the optional
    Given typeql write query
      """
      insert
      $x isa person, has name "Jeff", has ref 0;
      $y isa company, has name "Amazon", has ref 1;
      $r isa employment, links (employee: $x, employer: $y), has ref 2;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person; $y isa person; try { $r isa employment ($x, $y); };
      """
    Then uniquely identify answer concepts
      | x         | y         | r         |
      | key:ref:0 | key:ref:1 | key:ref:2 |


  Scenario: a non-matching optional returns none of the optional variables
    Given typeql write query
      """
      insert
      $x isa person, has name "Alice", has ref 0;
      $y isa person, has name "Bob", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Alice"; $y isa person, has name "Bob"; try { $r isa employment ($x, $y); };
      """
    Then answer size is: 1
    Then uniquely identify answer concepts
      | x         | y         | r    |
      | key:ref:0 | key:ref:1 | none |


  Scenario: a partially-matching optional behaves like a non-matching optional and returns none of the optional variables
    Given typeql write query
      """
      insert
      $x isa person, has name "Charlie", has ref 0;
      $y isa company, has name "Google", has ref 1;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Charlie"; $y isa company, has name "Google"; try { $r isa employment ($x, $y), has ref 100; };
      """
    Then answer size is: 1
    And answer has no variable: r


  Scenario: a conjunction can contain multiple sibling optionals
    Given typeql write query
      """
      insert
      $x isa person, has name "Dave", has ref 7;
      $y isa company, has name "Microsoft", has ref 8;
      $r1 isa employment, links (employee: $x, employer: $y), has ref 9;
      $z isa company, has name "Apple", has ref 10;
      $r2 isa employment, links (employee: $x, employer: $z), has ref 11;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match 
      $x isa person, has name "Dave";
      try { $y isa company, has name "Microsoft"; $r1 isa employment ($x, $y); };
      try { $z isa company, has name "Apple"; $r2 isa employment ($x, $z); };
      """
    Then uniquely identify answer concepts
      | x         | y         | r1        | z          | r2         |
      | key:ref:7 | key:ref:8 | key:ref:9 | key:ref:10 | key:ref:11 |


  Scenario: an optional can contain a nested optional
    Given typeql write query
      """
      insert
      $x isa person, has name "Eve", has ref 12;
      $y isa company, has name "Netflix", has ref 13;
      $r isa employment, links (employee: $x, employer: $y), has ref 14;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Eve"; 
      try { 
        $y isa company, has name "Netflix"; 
        $r isa employment ($x, $y);
        try { $y has name "Netflix"; };
      };
      """
    Then uniquely identify answer concepts
      | x          | y          | r          |
      | key:ref:12 | key:ref:13 | key:ref:14 |


  Scenario: an optional can be nested within a disjunction
    Given typeql write query
      """
      insert
      $x isa person, has name "Frank", has ref 15;
      $y isa company, has name "Tesla", has ref 16;
      $r isa employment, links (employee: $x, employer: $y), has ref 17;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name "Frank";
      {
        $y isa company, has name "Tesla";
        $r isa employment ($x, $y);
      } or {
        try { $y isa company, has name "Tesla"; $r isa employment ($x, $y); };
      };
      """
    Then uniquely identify answer concepts
      | x          | y          | r          |
      | key:ref:15 | key:ref:16 | key:ref:17 |


  Scenario: an optional cannot be used in a negation
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person; not { try { $y isa company; } };
      """
    Then the query is invalid, with error: ILLEGAL_STATE_QUERY_ILLEGAL_OPTIONAL_IN_NEGATION


  Scenario: sibling optionals must share the same parent variables, but overlap shared optional variables
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match 
      $x isa person, has name "Grace";
      try { $y isa company; $r1 isa employment ($x, $y); };
      try { $y isa company; $r2 isa employment ($x, $y); };
      """
    Then the query is invalid, with error: ILLEGAL_STATE_QUERY_OPTIONAL_VARIABLES_UNBOUNDED
