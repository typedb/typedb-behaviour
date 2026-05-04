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
    Given typeql schema query
    """
    define
      entity person
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
      attribute age, value integer;
      attribute ref value integer;
    """
    Given transaction commits


    Scenario: raw values can be used as inputs
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



    Scenario: concepts can be used as inputs
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


