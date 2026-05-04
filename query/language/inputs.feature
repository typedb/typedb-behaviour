# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Inputs Clause

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
    insert $p isa person, has name "John", has age 25, has ref 0;
    insert $p isa person, has name "Jane", has age 30, has ref 1;
    """
    Given transaction commits


    Scenario: raw values can be used as inputs
      Given connection open read transaction for database: typedb
      Given query inputs
        | n: string |
        | Jane      |

      When get answers of typeql read query with inputs
      """
      inputs $n: string;
      match $p isa person, has name == $n;
      """
      Then uniquely identify answers
        | p         |
        | key:ref:1 |


    Scenario: concepts can be used as inputs
      Given connection open read transaction for database: typedb
      Given query inputs
        | p: person      |
        | iid:entity:0:1 |
      When get answers of typeql read query with inputs
      """
      inputs $p: person;
      match $p has name $n;
      """
      Then uniquely identify answers
        | p              |
        | attr:name:Jane |


  Scenario: input variables cannot be reassigned to
    Given connection open read transaction for database: typedb
    Given query inputs
      """
      INPUTS
      """
    When get answers of typeql read query with inputs
      """
      READ QUERY
      """
    Then uniquely identify answers



  Scenario: Inputs may contain multiple rows
    Given connection open read transaction for database: typedb
    Given query inputs
      """
      INPUTS
      """
    When get answers of typeql read query with inputs
      """
      READ QUERY
      """
    Then uniquely identify answers



  Scenario: Input rows are checked against declared types
      TODO


    Scenario: Concepts in input rows are validated to exist
      TODO


    Scenario: Inputs can be used in write stages
      Given connection open write transaction for database: typedb
      Given query inputs
      """
      INPUTS
      """
      When get answers of typeql write query with inputs
      """
      READ QUERY
      """
      Then uniquely identify answers


