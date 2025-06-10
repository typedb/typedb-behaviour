# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required concept functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Concept

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb


# TODO: Uncomment when optional results are introduced
#  Scenario: Driver processes empty concepts correctly
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define entity person;
#      """
#    When get answers of typeql write query
#      """
#      match { $empty isa person; } or { $_ label person; };
#      """
#    Then answer type is: concept rows
#    Then answer size is: 1
#
#    Then answer get row(0) get variable(empty) is empty
#    Then answer get row(0) get variable by index(0) is empty


  Scenario: Driver processes entity types correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    When get answers of typeql read query
      """
      match entity $p;
      """
    Then answer type is: concept rows
    Then answer size is: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is instance: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: true
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false
    Then answer get row(0) get variable(p) is struct: false
    Then answer get row(0) get variable(p) is boolean: false

    Then answer get row(0) get variable(p) as entity type
    Then answer get row(0) get variable(p) try get label: person
    Then answer get row(0) get variable(p) get label: person
    Then answer get row(0) get variable(p) try get iid is none
    Then answer get row(0) get variable(p) try get value type is none
    Then answer get row(0) get variable(p) try get value is none
    Then answer get row(0) get variable(p) try get boolean is none
    Then answer get row(0) get variable(p) try get integer is none
    Then answer get row(0) get variable(p) try get double is none
    Then answer get row(0) get variable(p) try get decimal is none
    Then answer get row(0) get variable(p) try get string is none
    Then answer get row(0) get variable(p) try get date is none
    Then answer get row(0) get variable(p) try get datetime is none
    Then answer get row(0) get variable(p) try get datetime-tz is none
    Then answer get row(0) get variable(p) try get duration is none
    Then answer get row(0) get variable(p) try get struct is none
    Then answer get row(0) get type(p) get label: person
    Then answer get row(0) get entity type(p) try get label: person
    Then answer get row(0) get entity type(p) get label: person


  Scenario: Driver processes relation types correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define relation parentship, relates parent;
      """
    When get answers of typeql read query
      """
      match relation $p;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is instance: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: true
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false
    Then answer get row(0) get variable(p) is struct: false
    Then answer get row(0) get variable(p) is integer: false

    Then answer get row(0) get variable(p) as relation type
    Then answer get row(0) get variable(p) try get label: parentship
    Then answer get row(0) get variable(p) get label: parentship
    Then answer get row(0) get variable(p) try get iid is none
    Then answer get row(0) get variable(p) try get value type is none
    Then answer get row(0) get variable(p) try get value is none
    Then answer get row(0) get variable(p) try get boolean is none
    Then answer get row(0) get variable(p) try get integer is none
    Then answer get row(0) get variable(p) try get double is none
    Then answer get row(0) get variable(p) try get decimal is none
    Then answer get row(0) get variable(p) try get string is none
    Then answer get row(0) get variable(p) try get date is none
    Then answer get row(0) get variable(p) try get datetime is none
    Then answer get row(0) get variable(p) try get datetime-tz is none
    Then answer get row(0) get variable(p) try get duration is none
    Then answer get row(0) get variable(p) try get struct is none
    Then answer get row(0) get type(p) get label: parentship
    Then answer get row(0) get relation type(p) get label: parentship


  Scenario: Driver processes role types correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define relation parentship, relates parent;
      """
    When get answers of typeql read query
      """
      match $_ sub parentship, relates $p;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is instance: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: true
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false
    Then answer get row(0) get variable(p) is struct: false
    Then answer get row(0) get variable(p) is date: false

    Then answer get row(0) get variable(p) as role type
    Then answer get row(0) get variable(p) try get label: parentship:parent
    Then answer get row(0) get variable(p) get label: parentship:parent
    Then answer get row(0) get variable(p) try get iid is none
    Then answer get row(0) get variable(p) try get value type is none
    Then answer get row(0) get variable(p) try get value is none
    Then answer get row(0) get variable(p) try get boolean is none
    Then answer get row(0) get variable(p) try get integer is none
    Then answer get row(0) get variable(p) try get double is none
    Then answer get row(0) get variable(p) try get decimal is none
    Then answer get row(0) get variable(p) try get string is none
    Then answer get row(0) get variable(p) try get date is none
    Then answer get row(0) get variable(p) try get datetime is none
    Then answer get row(0) get variable(p) try get datetime-tz is none
    Then answer get row(0) get variable(p) try get duration is none
    Then answer get row(0) get variable(p) try get struct is none
    Then answer get row(0) get type(p) get label: parentship:parent
    Then answer get row(0) get role type(p) get label: parentship:parent


  Scenario: Driver processes attribute types without value type correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute untyped @abstract;
      """
    When get answers of typeql read query
      """
      match attribute $a;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is instance: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false
    Then answer get row(0) get variable(a) is boolean: false
    Then answer get row(0) get variable(a) is datetime-tz: false
    Then answer get row(0) get variable(a) try get value type is none
    Then answer get row(0) get variable(a) try get value is none
    Then answer get row(0) get variable(a) try get boolean is none
    Then answer get row(0) get variable(a) try get integer is none
    Then answer get row(0) get variable(a) try get double is none
    Then answer get row(0) get variable(a) try get decimal is none
    Then answer get row(0) get variable(a) try get string is none
    Then answer get row(0) get variable(a) try get date is none
    Then answer get row(0) get variable(a) try get datetime is none
    Then answer get row(0) get variable(a) try get datetime-tz is none
    Then answer get row(0) get variable(a) try get duration is none
    Then answer get row(0) get variable(a) try get struct is none

    Then answer get row(0) get variable(a) as attribute type
    Then answer get row(0) get variable(a) get label: untyped
    Then answer get row(0) get type(a) get label: untyped
    Then answer get row(0) get attribute type(a) get label: untyped

    Then answer get row(0) get attribute type(a) try get value type is none
    Then answer get row(0) get attribute type(a) is boolean: false
    Then answer get row(0) get attribute type(a) is integer: false
    Then answer get row(0) get attribute type(a) is double: false
    Then answer get row(0) get attribute type(a) is decimal: false
    Then answer get row(0) get attribute type(a) is string: false
    Then answer get row(0) get attribute type(a) is date: false
    Then answer get row(0) get attribute type(a) is datetime: false
    Then answer get row(0) get attribute type(a) is datetime-tz: false
    Then answer get row(0) get attribute type(a) is duration: false
    Then answer get row(0) get attribute type(a) is struct: false


  Scenario Outline: Driver processes attribute types with value type <value-type> correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute typed, value <value-type>;
      """
    When get answers of typeql read query
      """
      match attribute $a;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is instance: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false

    Then answer get row(0) get variable(a) as attribute type
    Then answer get row(0) get variable(a) get label: typed
    Then answer get row(0) get variable(a) try get value is none
    Then answer get row(0) get variable(a) try get boolean is none
    Then answer get row(0) get variable(a) try get integer is none
    Then answer get row(0) get variable(a) try get double is none
    Then answer get row(0) get variable(a) try get decimal is none
    Then answer get row(0) get variable(a) try get string is none
    Then answer get row(0) get variable(a) try get date is none
    Then answer get row(0) get variable(a) try get datetime is none
    Then answer get row(0) get variable(a) try get datetime-tz is none
    Then answer get row(0) get variable(a) try get duration is none
    Then answer get row(0) get variable(a) try get struct is none
    Then answer get row(0) get type(a) get label: typed
    Then answer get row(0) get attribute type(a) get label: typed

    Then answer get row(0) get attribute type(a) try get value type: <value-type>
    Then answer get row(0) get attribute type(a) is boolean: <is-boolean>
    Then answer get row(0) get attribute type(a) is integer: <is-integer>
    Then answer get row(0) get attribute type(a) is double: <is-double>
    Then answer get row(0) get attribute type(a) is decimal: <is-decimal>
    Then answer get row(0) get attribute type(a) is string: <is-string>
    Then answer get row(0) get attribute type(a) is date: <is-date>
    Then answer get row(0) get attribute type(a) is datetime: <is-datetime>
    Then answer get row(0) get attribute type(a) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get attribute type(a) is duration: <is-duration>
    Then answer get row(0) get attribute type(a) is struct: <is-struct>
    Examples:
      | value-type  | is-boolean | is-integer | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration | is-struct |
      | boolean     | true       | false      | false     | false      | false     | false   | false       | false          | false       | false     |
      | integer     | false      | true       | false     | false      | false     | false   | false       | false          | false       | false     |
      | double      | false      | false      | true      | false      | false     | false   | false       | false          | false       | false     |
      | decimal     | false      | false      | false     | true       | false     | false   | false       | false          | false       | false     |
      | string      | false      | false      | false     | false      | true      | false   | false       | false          | false       | false     |
      | date        | false      | false      | false     | false      | false     | true    | false       | false          | false       | false     |
      | datetime    | false      | false      | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime-tz | false      | false      | false     | false      | false     | false   | false       | true           | false       | false     |
      | duration    | false      | false      | false     | false      | false     | false   | false       | false          | true        | false     |


  Scenario: Driver processes attribute types with value type struct correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute film, value film-properties;
      struct film-genre:
        name value string,
        description value string,
        invented value date;
      struct film-properties:
        name value string,
        genre value film-genre,
        duration value duration,
        reviews value integer,
        score value double,
        revenue value decimal,
        premier value datetime,
        local-premier value datetime-tz,
        is-verified value boolean;
      """
    When get answers of typeql read query
      """
      match attribute $a;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is instance: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false

    Then answer get row(0) get variable(a) as attribute type
    Then answer get row(0) get variable(a) get label: film
    Then answer get row(0) get type(a) get label: film
    Then answer get row(0) get attribute type(a) get label: film

    Then answer get row(0) get attribute type(a) try get value type: film-properties
    Then answer get row(0) get attribute type(a) is boolean: false
    Then answer get row(0) get attribute type(a) is integer: false
    Then answer get row(0) get attribute type(a) is double: false
    Then answer get row(0) get attribute type(a) is decimal: false
    Then answer get row(0) get attribute type(a) is string: false
    Then answer get row(0) get attribute type(a) is date: false
    Then answer get row(0) get attribute type(a) is datetime: false
    Then answer get row(0) get attribute type(a) is datetime-tz: false
    Then answer get row(0) get attribute type(a) is duration: false
    Then answer get row(0) get attribute type(a) is struct: true


  Scenario: Driver processes entities correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person;
      """
    When get answers of typeql read query
      """
      match $p isa person;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(p) is type: false
    Then answer get row(0) get variable(p) is instance: true
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: true
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false
    Then answer get row(0) get variable(p) is struct: false
    Then answer get row(0) get variable(p) try get value is none
    Then answer get row(0) get variable(p) try get boolean is none
    Then answer get row(0) get variable(p) try get integer is none
    Then answer get row(0) get variable(p) try get double is none
    Then answer get row(0) get variable(p) try get decimal is none
    Then answer get row(0) get variable(p) try get string is none
    Then answer get row(0) get variable(p) try get date is none
    Then answer get row(0) get variable(p) try get datetime is none
    Then answer get row(0) get variable(p) try get datetime-tz is none
    Then answer get row(0) get variable(p) try get duration is none
    Then answer get row(0) get variable(p) try get struct is none

    Then answer get row(0) get variable(p) as entity
    Then answer get row(0) get variable(p) get label: person
    Then answer get row(0) get instance(p) get label: person
    Then answer get row(0) get instance(p) get type get label: person
    Then answer get row(0) get entity(p) try get iid is not none
    Then answer get row(0) get entity(p) contains iid
    Then answer get row(0) get entity(p) get label: person
    Then answer get row(0) get entity(p) get label: person
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get entity(p) get type is entity: false
    Then answer get row(0) get entity(p) get type is entity type: true
    Then answer get row(0) get entity(p) get type is relation type: false
    Then answer get row(0) get entity(p) get type is attribute type: false
    Then answer get row(0) get entity(p) get type is role type: false


  Scenario: Driver processes relations correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define relation parentship, relates parent;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa parentship;
      """
    When get answers of typeql read query
      """
      match $p isa parentship;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(p) is type: false
    Then answer get row(0) get variable(p) is instance: true
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: true
    Then answer get row(0) get variable(p) is attribute: false
    Then answer get row(0) get variable(p) is boolean: false
    Then answer get row(0) get variable(p) try get value is none
    Then answer get row(0) get variable(p) try get boolean is none
    Then answer get row(0) get variable(p) try get integer is none
    Then answer get row(0) get variable(p) try get double is none
    Then answer get row(0) get variable(p) try get decimal is none
    Then answer get row(0) get variable(p) try get string is none
    Then answer get row(0) get variable(p) try get date is none
    Then answer get row(0) get variable(p) try get datetime is none
    Then answer get row(0) get variable(p) try get datetime-tz is none
    Then answer get row(0) get variable(p) try get duration is none
    Then answer get row(0) get variable(p) try get struct is none

    Then answer get row(0) get variable(p) as relation
    Then answer get row(0) get variable(p) get label: parentship
    Then answer get row(0) get instance(p) get label: parentship
    Then answer get row(0) get instance(p) get type get label: parentship
    Then answer get row(0) get relation(p) try get iid is not none
    Then answer get row(0) get relation(p) contains iid
    Then answer get row(0) get relation(p) get label: parentship
    Then answer get row(0) get relation(p) get type get label: parentship
    Then answer get row(0) get relation(p) get type is relation: false
    Then answer get row(0) get relation(p) get type is entity type: false
    Then answer get row(0) get relation(p) get type is relation type: true
    Then answer get row(0) get relation(p) get type is attribute type: false
    Then answer get row(0) get relation(p) get type is role type: false


  Scenario Outline: Driver processes attributes of type <value-type> correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person, owns typed; attribute typed, value <value-type>;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person, has typed <value>;
      """
    When get answers of typeql read query
      """
      match $_ isa person, has $a;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(a) is type: false
    Then answer get row(0) get variable(a) is instance: true
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: false
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: true

    Then answer get row(0) get variable(a) as attribute
    Then answer get row(0) get variable(a) get label: typed
    Then answer get row(0) get instance(a) get label: typed
    Then answer get row(0) get instance(a) get type get label: typed
    Then answer get row(0) get attribute(a) get label: typed
    Then answer get row(0) get attribute(a) get type get label: typed
    Then answer get row(0) get attribute(a) get type is attribute: false
    Then answer get row(0) get attribute(a) get type is entity type: false
    Then answer get row(0) get attribute(a) get type is relation type: false
    Then answer get row(0) get attribute(a) get type is attribute type: true
    Then answer get row(0) get attribute(a) get type is role type: false

    Then answer get row(0) get attribute(a) get type get value type: <value-type>
    Then answer get row(0) get attribute(a) get <value-type>
    Then answer get row(0) get attribute(a) is boolean: <is-boolean>
    Then answer get row(0) get attribute(a) is integer: <is-integer>
    Then answer get row(0) get attribute(a) is double: <is-double>
    Then answer get row(0) get attribute(a) is decimal: <is-decimal>
    Then answer get row(0) get attribute(a) is string: <is-string>
    Then answer get row(0) get attribute(a) is date: <is-date>
    Then answer get row(0) get attribute(a) is datetime: <is-datetime>
    Then answer get row(0) get attribute(a) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get attribute(a) is duration: <is-duration>
    Then answer get row(0) get attribute(a) is struct: false
    Then answer get row(0) get attribute(a) try get value is: <value>
    Then answer get row(0) get attribute(a) try get <value-type> is: <value>
    Then answer get row(0) get attribute(a) try get value is not: <not-value>
    Then answer get row(0) get attribute(a) try get <value-type> is not: <not-value>
    Then answer get row(0) get attribute(a) get value is: <value>
    Then answer get row(0) get attribute(a) get <value-type> is: <value>
    Then answer get row(0) get attribute(a) get value is not: <not-value>
    Then answer get row(0) get attribute(a) get <value-type> is not: <not-value>
    Examples:
      | value-type  | value                                        | not-value                            | is-boolean | is-integer | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration |
      | boolean     | true                                         | false                                | true       | false      | false     | false      | false     | false   | false       | false          | false       |
      | integer     | 12345090                                     | 0                                    | false      | true       | false     | false      | false     | false   | false       | false          | false       |
      | double      | 0.0000000000000000001                        | 0.000000000000000001                 | false      | false      | true      | false      | false     | false   | false       | false          | false       |
      | double      | 2.01234567                                   | 2.01234568                           | false      | false      | true      | false      | false     | false   | false       | false          | false       |
      | decimal     | 1234567890.0001234567890dec                  | 1234567890.001234567890dec           | false      | false      | false     | true       | false     | false   | false       | false          | false       |
      | decimal     | 0.0000000000000000001dec                     | 0.000000000000000001dec              | false      | false      | false     | true       | false     | false   | false       | false          | false       |
      | string      | "John \"Baba Yaga\" Wick"                    | "John Baba Yaga Wick"                | false      | false      | false     | false      | true      | false   | false       | false          | false       |
      | date        | 2024-09-20                                   | 2025-09-20                           | false      | false      | false     | false      | false     | true    | false       | false          | false       |
      | datetime    | 1999-02-26T12:15:05                          | 1999-02-26T12:15:00                  | false      | false      | false     | false      | false     | false   | true        | false          | false       |
      | datetime    | 1999-02-26T12:15:05.000000001                | 1999-02-26T12:15:05.00000001         | false      | false      | false     | false      | false     | false   | true        | false          | false       |
      | datetime-tz | 2024-09-20T16:40:05 America/New_York         | 2024-06-20T15:40:05 America/New_York | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London  | 2024-09-20T16:40:05.000000001 UTC    | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/Belfast | 2024-09-20T16:40:05 Europe/Belfast   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0100           | 2024-09-20T16:40:05.000000001-0100   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+1115           | 2024-09-20T16:40:05.000000001+0000   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0000           | 2024-09-20T16:40:05+0000             | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | duration    | P1Y10M7DT15H44M5.00394892S                   | P1Y10M7DT15H44M5.0394892S            | false      | false      | false     | false      | false     | false   | false       | false          | true        |
      | duration    | P66W                                         | P67W                                 | false      | false      | false     | false      | false     | false   | false       | false          | true        |


  # TODO: Implement structs
#  Scenario: Driver processes attributes of type struct correctly
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity director, owns film;
#      attribute film, value film-properties;
#      struct film-genre:
#        name value string,
#        description value string,
#        invented value date;
#      struct film-properties:
#        name value string,
#        genre value film-genre,
#        duration value duration,
#        reviews value integer,
#        score value double,
#        revenue value decimal,
#        premier value datetime,
#        local-premier value datetime-tz,
#        is-verified value boolean;
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $d isa director, has film {
#        name: "Twin Peaks: Fire Walk with Me",
#        genre: film-genre {
#          name: surrealism,
#          description: "Surrealism is an art and cultural movement that developed in Europe in the aftermath of World War I in which artists aimed to allow the unconscious mind to express itself, often resulting in the depiction of illogical or dreamlike scenes and ideas. Its intention was, according to leader André Breton, to \"resolve the previously contradictory conditions of dream and reality into an absolute reality, a super-reality\", or surreality. It produced works of painting, writing, theatre, filmmaking, photography, and other media as well.",
#          invented: 1917-01-01,
#        },
#        duration: PT2H14M,
#        reviews: 130,
#        score: 45.13,
#        revenue: 4200000.123456789087654321,
#        premier: 1992-05-16T01:02:34,
#        local-premier: 1992-07-03T01:02:34 Europe/Paris,
#        is-verified: true,
#      };
#      """
#    When get answers of typeql read query
#      """
#      match $_ isa director, has $f;
#      """
#    Then answer type is: concept rows
#    Then answer query type is: read
#    Then answer size is: 1
#
#    Then answer get row(0) get variable(f) is type: false
#    Then answer get row(0) get variable(f) is instance: true
#    Then answer get row(0) get variable(f) is value: false
#    Then answer get row(0) get variable(f) is entity type: false
#    Then answer get row(0) get variable(f) is relation type: false
#    Then answer get row(0) get variable(f) is attribute type: false
#    Then answer get row(0) get variable(f) is role type: false
#    Then answer get row(0) get variable(f) is entity: false
#    Then answer get row(0) get variable(f) is relation: false
#    Then answer get row(0) get variable(f) is attribute: true
#
#    Then answer get row(0) get variable(f) as attribute
#    Then answer get row(0) get variable(f) get label: typed
#    Then answer get row(0) get instance(f) get label: typed
#    Then answer get row(0) get instance(f) get type get label: typed
#    Then answer get row(0) get attribute(f) get label: typed
#    Then answer get row(0) get attribute(f) get type get label: typed
#    Then answer get row(0) get attribute(f) get type is attribute: false
#    Then answer get row(0) get attribute(f) get type is entity type: false
#    Then answer get row(0) get attribute(f) get type is relation type: true
#    Then answer get row(0) get attribute(f) get type is attribute type: true
#    Then answer get row(0) get attribute(f) get type is role type: false
#
#    Then answer get row(0) get attribute(f) get type get value type: film-properties
#    Then answer get row(0) get attribute(f) is boolean: false
#    Then answer get row(0) get attribute(f) is integer: false
#    Then answer get row(0) get attribute(f) is double: false
#    Then answer get row(0) get attribute(f) is decimal: false
#    Then answer get row(0) get attribute(f) is string: false
#    Then answer get row(0) get attribute(f) is date: false
#    Then answer get row(0) get attribute(f) is datetime: false
#    Then answer get row(0) get attribute(f) is datetime-tz: false
#    Then answer get row(0) get attribute(f) is duration: false
#    Then answer get row(0) get attribute(f) is struct: true
#    Then answer get row(0) get attribute(f) try get value is: <value>
#    Then answer get row(0) get attribute(f) try get <value-type> is: <value>
#    Then answer get row(0) get attribute(f) try get value is not: <value>
#    Then answer get row(0) get attribute(f) try get <value-type> is not: <not-value>
#    Then answer get row(0) get attribute(f) get value is: <value>
#    Then answer get row(0) get attribute(f) get <value-type> is: <value>
#    Then answer get row(0) get attribute(f) get value is not: <value>
#    Then answer get row(0) get attribute(f) get <value-type> is not: <not-value>


  Scenario Outline: Driver processes values of type <value-type> correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person, owns typed; attribute typed, value <value-type>;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person, has typed <value>;
      """
    When get answers of typeql read query
      """
      match $_ isa person, has typed $v;
      let $value = $v;
      """
    Then answer type is: concept rows
    Then answer query type is: read
    Then answer size is: 1

    Then answer get row(0) get variable(value) is type: false
    Then answer get row(0) get variable(value) is instance: false
    Then answer get row(0) get variable(value) is value: true
    Then answer get row(0) get variable(value) is entity type: false
    Then answer get row(0) get variable(value) is relation type: false
    Then answer get row(0) get variable(value) is attribute type: false
    Then answer get row(0) get variable(value) is role type: false
    Then answer get row(0) get variable(value) is entity: false
    Then answer get row(0) get variable(value) is relation: false
    Then answer get row(0) get variable(value) is attribute: false
    Then answer get row(0) get variable(value) try get iid is none

    Then answer get row(0) get variable(value) as value
    Then answer get row(0) get variable(value) get label: <value-type>
    Then answer get row(0) get value(value) get label: <value-type>
    Then answer get row(0) get value(value) try get value type: <value-type>
    Then answer get row(0) get value(value) get value type: <value-type>
    Then answer get row(0) get value(value) is boolean: <is-boolean>
    Then answer get row(0) get value(value) is integer: <is-integer>
    Then answer get row(0) get value(value) is double: <is-double>
    Then answer get row(0) get value(value) is decimal: <is-decimal>
    Then answer get row(0) get value(value) is string: <is-string>
    Then answer get row(0) get value(value) is date: <is-date>
    Then answer get row(0) get value(value) is datetime: <is-datetime>
    Then answer get row(0) get value(value) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get value(value) is duration: <is-duration>
    Then answer get row(0) get value(value) is struct: false
    Then answer get row(0) get value(value) try get value is: <value>
    Then answer get row(0) get value(value) try get <value-type> is: <value>
    Then answer get row(0) get value(value) try get value is not: <not-value>
    Then answer get row(0) get value(value) try get <value-type> is not: <not-value>
    Then answer get row(0) get value(value) get is: <value>
    Then answer get row(0) get value(value) get <value-type> is: <value>
    Then answer get row(0) get value(value) get is not: <not-value>
    Then answer get row(0) get value(value) get <value-type> is not: <not-value>
    Examples:
      | value-type  | value                                        | not-value                            | is-boolean | is-integer | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration |
      | boolean     | true                                         | false                                | true       | false      | false     | false      | false     | false   | false       | false          | false       |
      | integer     | 12345090                                     | 0                                    | false      | true       | false     | false      | false     | false   | false       | false          | false       |
      | double      | 0.0000000000000000001                        | 0.000000000000000001                 | false      | false      | true      | false      | false     | false   | false       | false          | false       |
      | double      | 2.01234567                                   | 2.01234568                           | false      | false      | true      | false      | false     | false   | false       | false          | false       |
      | decimal     | 1234567890.0001234567890dec                  | 1234567890.001234567890dec           | false      | false      | false     | true       | false     | false   | false       | false          | false       |
      | decimal     | 0.0000000000000000001dec                     | 0.000000000000000001dec              | false      | false      | false     | true       | false     | false   | false       | false          | false       |
      | string      | "John \"Baba Yaga\" Wick"                    | "John Baba Yaga Wick"                | false      | false      | false     | false      | true      | false   | false       | false          | false       |
      | date        | 2024-09-20                                   | 2025-09-20                           | false      | false      | false     | false      | false     | true    | false       | false          | false       |
      | datetime    | 1999-02-26T12:15:05                          | 1999-02-26T12:15:00                  | false      | false      | false     | false      | false     | false   | true        | false          | false       |
      | datetime    | 1999-02-26T12:15:05.000000001                | 1999-02-26T12:15:05.00000001         | false      | false      | false     | false      | false     | false   | true        | false          | false       |
      | datetime-tz | 2024-09-20T16:40:05 America/New_York         | 2024-06-20T15:40:05 America/New_York | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London  | 2024-09-20T16:40:05.000000001 UTC    | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/Belfast | 2024-09-20T16:40:05 Europe/Belfast   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0100           | 2024-09-20T16:40:05.000000001-0100   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+1115           | 2024-09-20T16:40:05.000000001+0000   | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0000           | 2024-09-20T16:40:05+0000             | false      | false      | false     | false      | false     | false   | false       | true           | false       |
      | duration    | P1Y10M7DT15H44M5.00394892S                   | P1Y10M7DT15H44M5.0394892S            | false      | false      | false     | false      | false     | false   | false       | false          | true        |
      | duration    | P66W                                         | P67W                                 | false      | false      | false     | false      | false     | false   | false       | false          | true        |


  # TODO: Implement structs
#  Scenario: Driver processes values of type struct correctly
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity director, owns film;
#      attribute film, value film-properties;
#      struct film-genre:
#        name value string,
#        description value string,
#        invented value date;
#      struct film-properties:
#        name value string,
#        genre value film-genre,
#        duration value duration,
#        reviews value integer,
#        score value double,
#        revenue value decimal,
#        premier value datetime,
#        local-premier value datetime-tz,
#        is-verified value boolean;
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $d isa director, has film {
#        name: "Twin Peaks: Fire Walk with Me",
#        genre: film-genre {
#          name: surrealism,
#          description: "Surrealism is an art and cultural movement that developed in Europe in the aftermath of World War I in which artists aimed to allow the unconscious mind to express itself, often resulting in the depiction of illogical or dreamlike scenes and ideas. Its intention was, according to leader André Breton, to \"resolve the previously contradictory conditions of dream and reality into an absolute reality, a super-reality\", or surreality. It produced works of painting, writing, theatre, filmmaking, photography, and other media as well.",
#          invented: 1917-01-01,
#        },
#        duration: PT2H14M,
#        reviews: 130,
#        score: 45.13,
#        revenue: 4200000.123456789087654321,
#        premier: 1992-05-16T01:02:34,
#        local-premier: 1992-07-03T01:02:34 Europe/Paris,
#        is-verified: true,
#      };
#      """
#    When get answers of typeql read query
#      """
#      match $_ isa director, has film $v;
#      """
#    Then answer type is: concept rows
#    Then answer query type is: read
#    Then answer size is: 1
#
#    Then answer get row(0) get variable(v) get label: film-properties
#    Then answer get row(0) get variable(v) is type: false
#    Then answer get row(0) get variable(v) is instance: false
#    Then answer get row(0) get variable(v) is value: true
#    Then answer get row(0) get variable(v) is entity type: false
#    Then answer get row(0) get variable(v) is relation type: false
#    Then answer get row(0) get variable(v) is attribute type: false
#    Then answer get row(0) get variable(v) is role type: false
#    Then answer get row(0) get variable(v) is entity: false
#    Then answer get row(0) get variable(v) is relation: false
#    Then answer get row(0) get variable(v) is attribute: false
#
#    Then answer get row(0) get variable(v) as value
#    Then answer get row(0) get value(v) get value type: film-properties
#    Then answer get row(0) get value(v) is boolean: <is-boolean>
#    Then answer get row(0) get value(v) is integer: <is-integer>
#    Then answer get row(0) get value(v) is double: <is-double>
#    Then answer get row(0) get value(v) is decimal: <is-decimal>
#    Then answer get row(0) get value(v) is string: <is-string>
#    Then answer get row(0) get value(v) is date: <is-date>
#    Then answer get row(0) get value(v) is datetime: <is-datetime>
#    Then answer get row(0) get value(v) is datetime-tz: <is-datetime-tz>
#    Then answer get row(0) get value(v) is duration: <is-duration>
#    Then answer get row(0) get value(v) is struct: <is-struct>
#    Then answer get row(0) get value(v) get is: <value>
#    Then answer get row(0) get value(v) as <value-type> is: <value>
#    Then answer get row(0) get value(v) get is not: <not-value>
#    Then answer get row(0) get value(v) as <value-type> is not: <not-value>

  Scenario Outline: Driver processes values in concept documents correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person, owns typed;
      attribute typed, value <value-type>;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $p isa person, has typed <value>;
      """
    When get answers of typeql read query
      """
      match $_ isa person, has $a;
      fetch { "a": $a };
      """
    Then answer type is: concept documents
    Then answer query type is: read
    Then answer size is: 1
    Then answer contains document:
      """
      { "a": <expected> }
      """
    Then answer does not contain document:
      """
      { "a": <not-expected> }
      """
    When get answers of typeql read query
      """
      match $_ isa person, has $a; let $v = $a;
      fetch { "v": $v };
      """
    Then answer type is: concept documents
    Then answer query type is: read
    Then answer size is: 1
    Then answer contains document:
      """
      { "v": <expected> }
      """
    Then answer does not contain document:
      """
      { "v": <not-expected> }
      """
    Examples:
      | value-type  | value                                       | expected                                      | not-expected                                 |
      | boolean     | true                                        | true                                          | false                                        |
      | integer     | 12345090                                    | 12345090                                      | 0                                            |
      | double      | 0.0000000001                                | 0.0000000001                                  | 0.000000001                                  |
      | double      | 2.01234567                                  | 2.01234567                                    | 2.01234568                                   |
      | decimal     | 1234567890.0001234567890dec                 | "1234567890.000123456789dec"                  | "1234567890.0001234567890dec"                |
      | decimal     | 0.0000000000000000001dec                    | "0.0000000000000000001dec"                    | "0.000000000000000001dec"                    |
      | string      | "outPUT"                                    | "outPUT"                                      | "output"                                     |
      | date        | 2024-09-20                                  | "2024-09-20"                                  | "2025-09-20"                                 |
      | datetime    | 1999-02-26T12:15:05                         | "1999-02-26T12:15:05.000000000"               | "1999-02-26T12:15:05"                        |
      | datetime    | 1999-02-26T12:15:05.000000001               | "1999-02-26T12:15:05.000000001"               | "1999-02-26T12:15:05.000000000"              |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | "2024-09-20T16:40:05.000000001 Europe/London" | "2024-09-20T16:40:05.000000001Europe/London" |
      | datetime-tz | 2024-09-20T16:40:05.000000001+0100          | "2024-09-20T16:40:05.000000001+01:00"         | "2024-09-20T16:40:05.000000001+0100"         |
      | duration    | P1Y10M7DT15H44M5.00394892S                  | "P1Y10M7DT15H44M5.003948920S"                 | "P1Y10M7DT15H44M5.00394892S"                 |
      | duration    | P66W                                        | "P462D"                                       | "P66W"                                       |
    # TODO: Test documents and structs


  Scenario: Driver processes concept errors correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute age @independent, value integer; attribute name @independent, value string;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $a isa age 25; $n isa name "John";
      """

    When get answers of typeql read query
      """
      match $a isa age;
      """
    Then answer unwraps as ok; fails
    Then answer unwraps as concept documents; fails
    Then answer get row(0) get variable(unknown); fails with a message containing: "Cannot get concept from a concept row by variable 'unknown'"
    Then answer get row(0) get variable by index(15); fails with a message containing: "Cannot get concept from a concept row by index '15'"
    Then answer get row(0) get variable(); fails with a message containing: "Cannot get concept from a concept row by variable ''"
    Then answer get row(0) get variable( ); fails with a message containing: "Cannot get concept from a concept row by variable ' '"
    Then answer get row(0) get variable(a) as entity; fails with a message containing: "Invalid concept conversion"
    Then answer get row(0) get variable(a) as attribute type; fails with a message containing: "Invalid concept conversion"
    Then answer get row(0) get variable(a) as value; fails with a message containing: "Invalid concept conversion"
    Then answer get row(0) get attribute(a) get boolean; fails with a message containing: "Could not retrieve a 'boolean' value"
    Then answer get row(0) get attribute(a) get double; fails with a message containing: "Could not retrieve a 'double' value"
    Then answer get row(0) get attribute(a) get decimal; fails with a message containing: "Could not retrieve a 'decimal' value"
    Then answer get row(0) get attribute(a) get string; fails with a message containing: "Could not retrieve a 'string' value"
    Then answer get row(0) get attribute(a) get date; fails with a message containing: "Could not retrieve a 'date' value"
    Then answer get row(0) get attribute(a) get datetime; fails with a message containing: "Could not retrieve a 'datetime' value"
    Then answer get row(0) get attribute(a) get datetime-tz; fails with a message containing: "Could not retrieve a 'datetime-tz' value"
    Then answer get row(0) get attribute(a) get duration; fails with a message containing: "Could not retrieve a 'duration' value"
    Then answer get row(0) get attribute(a) get struct; fails with a message containing: "Could not retrieve a 'struct' value"

    When get answers of typeql read query
      """
      match $n isa name;
      """
    Then answer unwraps as ok; fails
    Then answer unwraps as concept documents; fails
    Then answer get row(0) get variable(n) as relation; fails with a message containing: "Invalid concept conversion"
    Then answer get row(0) get attribute(n) get integer; fails with a message containing: "Could not retrieve a 'integer' value"

    Then typeql read query; fails with a message containing: "syntax error"
      """
      """
    Then typeql read query; fails with a message containing: "syntax error"
      """

      """


  Scenario: Driver processes datetime values in different user time-zones identically
    Given set time-zone: Asia/Calcutta
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute dt @independent, value datetime;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $dt isa dt 2023-05-01T00:00:00;
      """
    Then answer get row(0) get attribute(dt) get value is: 2023-05-01T00:00:00
    Then answer get row(0) get attribute(dt) get value is not: 2023-04-30T13:30:00

    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00
    When transaction commits

    When connection closes
    When set time-zone: America/Chicago
    When connection opens with default authentication

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00


  Scenario: Driver processes datetime-tz values in different user time-zones identically
    Given set time-zone: Asia/Calcutta
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define attribute dt @independent, value datetime-tz;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $dt isa dt 2023-05-01T00:00:00 Asia/Calcutta;
      """
    Then answer get row(0) get attribute(dt) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(dt) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(dt) get value is not: 2023-05-01T00:00:00 America/Chicago

    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-05-01T00:00:00 America/Chicago
    When transaction commits

    When connection closes
    When set time-zone: America/Chicago
    When connection opens with default authentication

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-05-01T00:00:00 America/Chicago

    When connection closes
    When set time-zone: Europe/London
    When connection opens with default authentication

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-05-01T00:00:00 America/Chicago
