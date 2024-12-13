# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Function Body Structure

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
        owns name @card(0..),
        owns age @card(0..),
        owns ref @key;
      attribute name value string;
      attribute age @independent, value long;
      attribute ref value long;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $p1 isa person, has name "Alice", has name "Allie", has age 10, has ref 0;
      $p2 isa person, has name "Bob", has age 12, has ref 1;
      $p3 isa person, has name "Charlie", has age 9, has ref 2;
      $p4 isa person, has name "Dave", has age 11, has ref 3;
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
    match let $p in alice_or_bob();
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
    match let $p in not_alice_or_bob();
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:2 |
      | key:ref:3 |


  Scenario: Sort, Offset & Limit can be used in function bodies.
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun second_and_third_largest_ages() -> { age }:
      match
        $p isa person, has age $age;
      sort $age desc;
      offset 1;
      limit 2;
      return { $age };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match let $age in second_and_third_largest_ages();
    """
    Then order of answer concepts is
      | age         |
      | attr:age:11 |
      | attr:age:10 |


  Scenario: Reduce can be used in function bodies
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun sum_all_ages() -> { long }:
      match
        $p isa person, has age $age;
      reduce $sum_ages = sum($age);
      return { $sum_ages };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
    """
    match let $sum_ages in sum_all_ages();
    """
    Then uniquely identify answer concepts
      | sum_ages      |
      | value:long:42 |


  Scenario: A function may not have write stages in the body
    Given connection open schema transaction for database: typedb
    Given typeql schema query; fails
      """
      define
      fun try_adding_an_age_to_alice() -> { person }:
      match
        $p isa person;
      insert
        $p has age 1;
      return { $p };
      """

