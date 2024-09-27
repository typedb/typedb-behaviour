# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Get Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write

    Given typeql define
      """
      define
      person sub entity,
        plays friendship:friend,
        plays employment:employee,
        owns name,
        owns age,
        owns ref @key;
      company sub entity,
        plays employment:employer,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      employment sub relation,
        relates employee,
        relates employer,
        owns ref @key;
      name sub attribute, value string;
      age sub attribute, value long;
      ref sub attribute, value long;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write


  #############
  # VARIABLES #
  #############

  Scenario: 'get' can be used to restrict the set of variables that appear in an answer set
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
      get $z, $x;
      """
    Then uniquely identify answer concepts
      | z         | x               |
      | key:ref:0 | attr:name:Lisa  |


  Scenario: when a 'get' has unbound variables, an error is thrown
    Then typeql throws exception
      """
      match $x isa person; get $y;
      """


  Scenario: Value variables can be specified in a 'get'
    Given typeql insert
      """
      insert
      $x "Lisa" isa name;
      $y 16 isa age;
      $z isa person, has name $x, has age $y, has ref 0;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $z isa person, has name $x, has age $y;
        ?b = 2017 - $y;
      get $z, $x, ?b;
      """
    Then uniquely identify answer concepts
      | z         | x              | b                |
      | key:ref:0 | attr:name:Lisa | value:long:2001  |


  # Guards against regression of #6967
  Scenario: A `get` filter is applied after negations
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Klaus", has ref 0;
      $p2 isa person, has name "Kristina", has ref 1;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n = "Klaus";
        not { $p has name "Kristina"; };
      get $n, $r;
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |

    When get answers of typeql read query
      """
      match
        $p isa person, has name $n, has ref $r;
        $n = "Klaus";
        not { $p has name "Kristina"; };
      get $n, $r;
      sort $r; # The sort triggered the bug
      """
    Then uniquely identify answer concepts
      | n               | r               |
      | attr:name:Klaus | attr:ref:0      |


  #########
  # GROUP #
  #########

  Scenario: answers can be grouped by a variable contained in the answer set
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $p3 isa person, has name "Bernard", has ref 2;
      $p4 isa person, has name "Colin", has ref 3;
      $f (friend: $p1, friend: $p2, friend: $p3, friend: $p4) isa friendship, has ref 4;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query
      """
      match ($x, $y) isa friendship;
      """
    Then uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:1 |
      | key:ref:0 | key:ref:2 |
      | key:ref:0 | key:ref:3 |
      | key:ref:1 | key:ref:0 |
      | key:ref:1 | key:ref:2 |
      | key:ref:1 | key:ref:3 |
      | key:ref:2 | key:ref:0 |
      | key:ref:2 | key:ref:1 |
      | key:ref:2 | key:ref:3 |
      | key:ref:3 | key:ref:0 |
      | key:ref:3 | key:ref:1 |
      | key:ref:3 | key:ref:2 |
    When get answers of typeql read query group
      """
      match ($x, $y) isa friendship;

      group $x;
      """
    Then answer groups are
      | owner     | x         | y         |
      | key:ref:0 | key:ref:0 | key:ref:1 |
      | key:ref:0 | key:ref:0 | key:ref:2 |
      | key:ref:0 | key:ref:0 | key:ref:3 |
      | key:ref:1 | key:ref:1 | key:ref:0 |
      | key:ref:1 | key:ref:1 | key:ref:2 |
      | key:ref:1 | key:ref:1 | key:ref:3 |
      | key:ref:2 | key:ref:2 | key:ref:0 |
      | key:ref:2 | key:ref:2 | key:ref:1 |
      | key:ref:2 | key:ref:2 | key:ref:3 |
      | key:ref:3 | key:ref:3 | key:ref:0 |
      | key:ref:3 | key:ref:3 | key:ref:1 |
      | key:ref:3 | key:ref:3 | key:ref:2 |

  Scenario: answers can be grouped by a value variable contained in the answer set
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 1250;
      $p2 isa person, has name "Rupert", has ref 1750;
      $p3 isa person, has name "Bernard", has ref 2050;
      $p4 isa person, has name "Colin", has ref 3000;
      """
    Given transaction commits

    Given session opens transaction of type: read
    When get answers of typeql read query group
      """
      match
       $x isa person, has ref $r;
       ?bracket = floor($r/1000) * 1000;
       get $x, ?bracket;
       group ?bracket;
      """
    Then answer groups are
      | owner           | x            |
      | value:long:1000 | key:ref:1250 |
      | value:long:1000 | key:ref:1750 |
      | value:long:2000 | key:ref:2050 |
      | value:long:3000 | key:ref:3000 |

  Scenario: when grouping answers by a variable that is not contained in the answer set, an error is thrown
    Given typeql insert
      """
      insert
      $p1 isa person, has name "Violet", has ref 0;
      $p2 isa person, has name "Rupert", has ref 1;
      $f (friend: $p1, friend: $p2) isa friendship, has ref 2;
      """
    Given transaction commits

    Given session opens transaction of type: read
    Then typeql get group; throws exception
      """
      match ($x, $y) isa friendship;
      get $x;
      group $y;
      """

