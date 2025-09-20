# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Basic Analyze queries

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
      entity person, owns name, owns ref @key;
      attribute ref value integer;
      attribute name value string;
      """
    Given transaction commits


  Scenario: Analyze returns the constraints in a query, and the pipeline structure
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match $x isa person;
      """
    Then analyzed query structure is:
    """
    QueryStructure(
      Query(
        Pipeline([
          Match([Isa($x, person)])
        ])
      ),
      Preamble([])
    )
    """
    Given transaction closes
