# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Update Query

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person,
        plays friendship:friend,
        plays parenthood:parent,
        plays parenthood:child,
        owns name,
        owns ref @key;
      relation friendship,
        relates friend,
        owns ref @key;
      relation parenthood,
        relates parent,
        relates child;
      attribute name, value string;
      attribute ref, value integer;
      """
    Given transaction commits


  Scenario: Update owned attribute without side effects on other owners
    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
      """
      insert
        $x isa person, has name "Alex", has ref 0;
        $y isa person, has name "Alex", has ref 1;
      """
    Given uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:1 |
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match
      $x isa person, has ref 1, has $n;
      $n isa name;
      delete has $n of $x;
      insert $x has name "Bob";
      """
    Then transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | x         | n               |
      | key:ref:0 | attr:name:Alex  |
      | key:ref:1 | attr:name:Bob   |


  Scenario: Roleplayer exchange
    Given connection open write transaction for database: typedb
    Given get answers of typeql write query
      """
      insert
      $x isa person, has name "Alex", has ref 0;
      $y isa person, has name "Bob", has ref 1;
      $r isa parenthood (parent: $x, child:$y);
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When typeql write query
      """
      match $r isa parenthood (parent: $x, child: $y);
      delete $r;
      insert $q isa parenthood (parent: $y, child: $x);
      """


  Scenario: Complex migration
    Given connection open write transaction for database: typedb
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
      match $att isa name;
      insert $x isa nameclass, has $att;
      """
    When typeql write query
      """
      match
      $p isa person, has name $n;
      $nc isa nameclass, has name $n;
      delete has $n of $p;
      insert (named: $p, name: $nc) isa naming;
      """
    Then transaction commits
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      (named: $p, name: $nc) isa naming;
      $nc has name $n;

      """
    Then uniquely identify answer concepts
      | p         | n                  |
      | key:ref:0 | attr:name:Alex     |
      | key:ref:1 | attr:name:Bob      |
      | key:ref:2 | attr:name:Charlie  |
      | key:ref:3 | attr:name:Darius   |
      | key:ref:4 | attr:name:Alex     |
      | key:ref:5 | attr:name:Bob      |

    When get answers of typeql read query
      """
      match
      $p isa person;
      $p has name $n;

      """
    Then answer size is: 0



