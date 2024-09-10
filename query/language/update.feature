# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Update Query

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
        plays parenthood:parent,
        plays parenthood:child,
        owns name,
        owns ref @key;
      friendship sub relation,
        relates friend,
        owns ref @key;
      parenthood sub relation,
        relates parent,
        relates child;
      name sub attribute, value string;
      ref sub attribute, value long;
      """
    Given transaction commits

    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write


  Scenario: Deleting anonymous variables throws an exception
    Given get answers of typeql insert
      """
      insert
        $x isa person, has name "Alex", has ref 0;
        $y isa person, has name "Alex", has ref 1;
        (friend: $y) isa friendship, has ref 2;
      """
    Given transaction commits
    Given session opens transaction of type: write
    Then typeql update; throws exception
      """
      match
      $x isa person, has ref 1;
      delete $x has name "Alex";
      insert $x has name "Bob";
      """
    Given session transaction closes
    Given session opens transaction of type: write
    Then typeql update; throws exception
      """
      match
      $x isa person, has ref 1;
      delete (friend: $x) isa friendship;
      insert (parent: $x) isa parentship;
      """



  Scenario: Update owned attribute without side effects on other owners
    Given get answers of typeql insert
      """
      insert
        $x isa person, has name "Alex", has ref 0;
        $y isa person, has name "Alex", has ref 1;
      """
    Given uniquely identify answer concepts
      | x         | y         |
      | key:ref:0 | key:ref:1 |
    Given transaction commits
    Given session opens transaction of type: write
    When typeql update
      """
      match
      $x isa person, has ref 1, has $n;
      $n isa name;
      delete $x has $n;
      insert $x has name "Bob";
      """
    Then transaction commits
    When session opens transaction of type: read
    When get answers of typeql read query
      """
      match $x isa person, has name $n;
      """
    Then uniquely identify answer concepts
      | x         | n               |
      | key:ref:0 | attr:name:Alex  |
      | key:ref:1 | attr:name:Bob   |


  Scenario: Roleplayer exchange
    Given get answers of typeql insert
      """
      insert
      $x isa person, has name "Alex", has ref 0;
      $y isa person, has name "Bob", has ref 1;
      $r (parent: $x, child:$y) isa parenthood;
      """
    Given transaction commits
    Given session opens transaction of type: write
    When typeql update
      """
      match $r (parent: $x, child: $y) isa parenthood;
      delete $r isa parenthood;
      insert (parent: $y, child: $x) isa parenthood;
      """


  Scenario: Unrelated insertion
    Given get answers of typeql insert
      """
      insert
      $x isa person, has name "Alex", has ref 0;
      """
    Given transaction commits
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql update; throws exception
      """
      match $p isa person;
      delete $p isa person;
      insert $x isa entity;
      """


  Scenario: Complex migration
    Given get answers of typeql insert
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
    Given connection close all sessions
    Given connection open schema session for database: typedb
    Given session opens transaction of type: write
    Given typeql define
      """
      define
      nameclass sub entity,
        owns name @key,
        plays naming:name;
      naming sub relation,
        relates named,
        relates name;
      person plays naming:named;
      """
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for database: typedb
    Given session opens transaction of type: write
    When typeql insert
      """
      match $att isa name;
      insert $x isa nameclass, has $att;
      """
    When typeql update
      """
      match
      $p isa person, has name $n;
      $nc isa nameclass, has name $n;
      delete $p has $n;
      insert (named: $p, name: $nc) isa naming;
      """
    Then transaction commits
    When session opens transaction of type: read
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



