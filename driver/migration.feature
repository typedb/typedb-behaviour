# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required migration functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Migration

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  ##########
  # EXPORT #
  ##########

  Scenario: Exported database's schema is the same as the one from database schema interface
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person @abstract, owns age @card(1..1);
        entity real-person sub person;
        entity not-real-person @abstract, sub person;
        attribute age, value integer @range(0..150);
        relation friendship, relates friend;
        relation best-friendship sub friendship, relates best-friend as friend;

        fun age($person: person) -> age:
          match
            $person has $age;
            $age isa age;
          return first $age;
      """
    Given typeql write query
      """
      insert
        # TODO
      """
    Given transaction commits

    Given file(schema.tql) does not exist
    Given file(data.typedb) does not exist
    When database export to schema file(schema.tql), data file(data.typedb)
    Then file(schema.tql) exists
    Then file(data.typedb) exists
    Then file(schema.tql) is not empty
    Then file(data.typedb) is not empty
    Then file(schema.tql) contains:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..150);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;

      fun age($person: person) -> age:
        match
          $person has $age;
          $age isa age;
        return first $age;
    """

    When connection open read transaction for database: typedb
    Then connection get database(typedb) has schema:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..150);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;

      fun age($person: person) -> age:
        match
          $person has $age;
          $age isa age;
        return first $age;
    """

# TODO: Cover errors

  ##########
  # IMPORT #
  ##########

  # TODO: Cover everything
