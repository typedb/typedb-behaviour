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


  Scenario: Analyze returns the structure of each stage in the query
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      match $x isa person;
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([Isa($x, person)])
    ])
    """
    Given transaction closes


  Scenario: Analyze returns the structure of each function in the preamble
    Given connection open read transaction for database: typedb
    When get answers of typeql analyze query
      """
      with
      fun persons() -> { person }:
      match $p isa person;
      return { $p };

      with
      fun name_of($p: person) -> { name }:
      match $p has name $n;
      return { $n };

      match $x isa person;
      """
    Then analyzed query preamble contains:
    """
    Function(
      [],
      Stream([$p]),
      Pipeline([
        Match([Isa($p, person)])
      ])
    )
    """
    Then analyzed query preamble contains:
    """
    Function(
      [$p],
      Stream([$n]),
      Pipeline([
        Match([
          Has($p, $n),
          Isa($n, name)
        ])
      ])
    )
    """
    Given transaction closes
