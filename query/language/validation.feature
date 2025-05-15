# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Validation

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
        owns name @card(0..);
      attribute name value string;
      """
    Given transaction commits

  Scenario: Disjunction local variables are not visible in downstream stages

  Scenario: Disjunction local variables are not visible in subsequent stages
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'p' was not available in the stage"
      """
      match
       { $p isa person; } or { $k isa person; };
      select $p;
      """
    Given transaction closes


  Scenario: Deleted variables are not visible in subsequent stages
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'p' was not available in the stage"
      """
      match
       $p isa person;
      delete
       $p;
      select $p;
      """
    Given transaction closes


  Scenario: Reduced variables are not visible in subsequent stages
    Given connection open read transaction for database: typedb
    Then typeql read query; fails with a message containing: "The variable 'p' was not available in the stage"
      """
      match
       $p isa person;
      reduce $c = count($p);
      select $p;
      """
    Given transaction closes
