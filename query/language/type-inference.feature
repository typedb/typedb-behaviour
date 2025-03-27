# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Type Inference tests

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
      entity person, owns name;
      attribute name, value string;
    """
    Given transaction commits


  Scenario: Variables involved in an 'is' constraint must belong to the same category.
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $p1 isa person, has name "John";
      $p2 isa person, has name "James";
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql read query; fails with a message containing: "The variable categories for the is statement are incompatible"
    """
    match
      $p is $n;
      $p isa person, has name $n;
    """
