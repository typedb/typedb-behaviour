# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Tests for various shapes of function bodies

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
      entity person
        plays friendship:friend,
        plays employment:employee,
        owns name @card(0..),
        owns age @card(0..),
        owns ref @key;
      entity company
        plays employment:employer,
        owns name @card(0..),
        owns ref @key;
      relation friendship
        relates friend @card(0..),
        owns ref @key;
      relation employment
        relates employee @card(0..),
        relates employer @card(0..),
        owns ref @key;
      attribute name value string;
      attribute age @independent, value long;
      attribute ref value long;
      attribute email value string;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has name "Alice", has name "Allie", has age 10, has ref 0;
      $p2 isa person, has name "Bob", has ref 1;
      $p3 isa person, has name "Charlie", has ref 2;
      """
    Given transaction commits


  Scenario: a function with disjunctions considers every branch
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun alice_or_bob() -> { person }:
      match
        $p isa person;
        { $p has name "Alice"; } or { $p has name "Bob"; };
      return { $p };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match $p in alice_or_bob();
    """
    Then uniquely identify answer concepts
     | p         |
     | key:ref:0 |
     | key:ref:1 |


  Scenario: a function with negated disjunctions considers every branch
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun not_alice_or_bob() -> { person }:
      match
        $p isa person;
        not { { $p has name "Alice"; } or { $p has name "Bob"; }; };
      return { $p };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match $p in not_alice_or_bob();
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:2 |



  Scenario: Functions which do not return the specified type are an error
    # TODO


  Scenario: Sort, Offset & Limit can be used in function bodies. Further, the results remains consistent across runs.
    # TODO


  Scenario: Reduce can be used in function bodies
    # TODO

  Scenario: A function may not have write stages in the body
    # TODO


