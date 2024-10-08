# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required functionality of TypeDB drivers. Can be used to test any client
# application which aims to support all the operations presented in this file for the complete user experience.
# The following steps are suitable for both CORE and CLOUD drivers. It is recommended to test both of them.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: TypeDB Driver

  Background: Open connection / create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  ##############
  # CONNECTION #
  ##############

  Scenario: Driver can close connection
    When connection closes
    Then connection is open: false


  Scenario: Driver can connect after an unsuccessful connection attempt
    When connection closes
    When connection opens with a wrong port; fails
    Then connection is open: false
    When connection opens with a wrong host; fails
    Then connection is open: false
    When connection opens with default authentication
    Then connection is open: true


  Scenario: Driver can reconnect multiple times
    Given connection is open: true
    Given connection has database: typedb
    When connection opens with default authentication
    Then connection is open: true
    Then connection has database: typedb

    When connection opens with default authentication
    Then connection is open: true
    Then connection has database: typedb

    When connection closes
    Then connection is open: false

    When connection closes
    Then connection is open: false

    When connection opens with default authentication
    Then connection is open: true
    Then connection has database: typedb


    # TODO: Test credentials (should be available for CORE as well)

  #############
  # DATABASES #
  #############

  Scenario: Driver cannot delete non-existing database
    Given connection does not have database: does-not-exist
    Then connection delete database: does-not-exist; fails
    Then connection does not have database: does-not-exist

  Scenario: Driver can create and delete databases
    Given connection does not have database: An0ther-database_with-1onG-Name
    When connection create database: An0ther-database_with-1onG-Name
    Then connection has 2 databases
    Then connection has databases:
      | typedb                          |
      | An0ther-database_with-1onG-Name |
    Then connection does not have databases:
      | typedB                          |
      | Typedb                          |
      | TYPEDB                          |
      | An0ther_database_with-1onG-Name |
      | An0ther-database-with-1onG-Name |
      | an0ther-database_with-1onG-Name |
    When connection closes
    Then connection is open: false
    When connection opens with default authentication
    Then connection is open: true
    Then connection has 2 databases
    Then connection has databases:
      | typedb                          |
      | An0ther-database_with-1onG-Name |
    Then connection does not have databases:
      | typedB                          |
      | Typedb                          |
      | TYPEDB                          |
      | An0ther_database_with-1onG-Name |
      | An0ther-database-with-1onG-Name |
      | an0ther-database_with-1onG-Name |

    When connection delete database: typedb
    Then connection has 1 database
    Then connection does not have database: typedb
    Then connection has database: An0ther-database_with-1onG-Name
    When connection closes
    Then connection is open: false
    When connection opens with default authentication
    Then connection is open: true
    Then connection has 1 database
    Then connection does not have database: typedb
    Then connection has database: An0ther-database_with-1onG-Name

    When connection delete database: An0ther-database_with-1onG-Name
    Then connection has 0 databases
    Then connection does not have database: An0ther-database_with-1onG-Name
    Then connection does not have database: typedb
    Then connection has 0 databases
    When connection closes
    Then connection is open: false
    When connection opens with default authentication
    Then connection is open: true
    Then connection has 0 databases
    When connection create database: typedb
    Then connection has database: typedb


# TODO: Implement database schema retrieval. Fix steps if needed.
#  Scenario: Driver can acquire database schema
#    Given connection has database: typedb
#    Then connection get database(typedb) has schema:
#    """
#    """
#    Then connection get database(typedb) has type schema:
#    """
#    """
#
#    When connection open schema transaction for database: typedb
#    When typeql schema query
#    """
#    define
#    entity person @abstract, owns age @card(1..1);
#    attribute age, value long @range(0..150);
#    """
#    Then connection get database(typedb) has schema:
#    """
#    """
#    Then connection get database(typedb) has type schema:
#    """
#    """
#    When transaction commits
#    Then connection get database(typedb) has schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1);
#    attribute age, value long @range(0..150);
#    """
#    Then connection get database(typedb) has type schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1);
#    attribute age, value long @range(0..150);
#    """
#
#    When connection open schema transaction for database: typedb
#    When typeql schema query
#    """
#    redefine
#    attribute age, value long @range(0..);
#    """
#    When typeql schema query
#    """
#    define
#    entity person owns age @range(0..150);
#    entity fictional-character owns age;
#    """
#    Then connection get database(typedb) has schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1);
#    attribute age, value long @range(0..150);
#    """
#    Then connection get database(typedb) has type schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1);
#    attribute age, value long @range(0..150);
#    """
#    When transaction commits
#    Then connection get database(typedb) has schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1) @range(0..150);
#    entity fictional-character owns age;
#    attribute age, value long @range(0..);
#    """
#    Then connection get database(typedb) has type schema:
#    """
#    define
#    entity person @abstract, owns age @card(1..1) @range(0..150);
#    entity fictional-character owns age;
#    attribute age, value long @range(0..);
#    """

  ###############
  # TRANSACTION #
  ###############

  Scenario: Driver cannot open transaction to non-existing database
    Given connection does not have database: does-not-exist
    Then transaction is open: false
    Then connection open schema transaction for database: does-not-exist; fails
    Then transaction is open: false
    Then connection open write transaction for database: does-not-exist; fails
    Then transaction is open: false
    Then connection open read transaction for database: does-not-exist; fails
    Then transaction is open: false


  Scenario: Driver can open and close transactions of different types
    Then transaction is open: false
    When connection open schema transaction for database: typedb
    Then transaction has type: schema
    Then transaction is open: true
    When transaction closes
    Then transaction is open: false

    When connection open write transaction for database: typedb
    Then transaction has type: write
    Then transaction is open: true
    When transaction closes
    Then transaction is open: false

    When connection open read transaction for database: typedb
    Then transaction has type: read
    Then transaction is open: true
    When transaction closes
    Then transaction is open: false


  Scenario: Driver can commit transactions of schema and write types, cannot commit transaction of type read
    When connection open schema transaction for database: typedb
    Then transaction has type: schema
    Then transaction is open: true
    When transaction commits
    Then transaction is open: false

    When connection open write transaction for database: typedb
    Then transaction has type: write
    Then transaction is open: true
    When transaction commits
    Then transaction is open: false

    When connection open read transaction for database: typedb
    Then transaction has type: read
    Then transaction is open: true
    Then transaction commits; fails
    Then transaction is open: false


  # TODO: Fix rollbacks on the server side
#  Scenario: Driver can rollback transactions of schema and write types, cannot rollback transaction of type read
#    When connection open schema transaction for database: typedb
#    Then transaction has type: schema
#    Then transaction is open: true
#    When transaction rollbacks
#    Then transaction is open: false
#
#    When connection open write transaction for database: typedb
#    Then transaction has type: write
#    Then transaction is open: true
#    When transaction rollbacks
#    Then transaction is open: false
#
#    When connection open read transaction for database: typedb
#    Then transaction has type: read
#    Then transaction is open: true
#    Then transaction rollbacks; fails
#    Then transaction is open: false


  # TODO: Check options setting and retrieval


  # TODO: Fix on_close
#  Scenario: Driver can schedule "transaction on close" jobs
#    Given connection does not have database: created-after-schema
#    Given connection does not have database: created-after-write
#    Given connection does not have database: created-after-read
#    When connection open schema transaction for database: typedb
#    When schedule database creation on transaction close: created-after-schema
#    Then connection does not have database: created-after-schema
#    Then connection does not have database: created-after-write
#    Then connection does not have database: created-after-read
#    When transaction closes
#    Then connection has database: created-after-schema
#    Then connection does not have database: created-after-write
#    Then connection does not have database: created-after-read
#
#    When connection open write transaction for database: typedb
#    Then connection has database: created-after-schema
#    Then connection does not have database: created-after-write
#    Then connection does not have database: created-after-read
#    When transaction closes
#    Then connection has database: created-after-schema
#    Then connection does not have database: created-after-write
#    Then connection does not have database: created-after-read
#
#    When connection open write transaction for database: typedb
#    When schedule database creation on transaction close: created-after-write
#    Then connection has database: created-after-schema
#    Then connection does not have database: created-after-write
#    Then connection does not have database: created-after-read
#    When transaction closes
#    Then connection has database: created-after-schema
#    Then connection has database: created-after-write
#    Then connection does not have database: created-after-read
#
#    When connection open read transaction for database: typedb
#    When schedule database creation on transaction close: created-after-read
#    Then connection has database: created-after-schema
#    Then connection has database: created-after-write
#    Then connection does not have database: created-after-read
#    When transaction closes
#    Then connection has database: created-after-schema
#    Then connection has database: created-after-write
#    Then connection has database: created-after-read


  Scenario: Driver processes transaction commit errors correctly
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define attribute name;
      """
    Then transaction commits; fails


  # TODO: check errors on transaction commits with callbacks (on_close) set!

  ###########
  # QUERIES #
  ###########

  Scenario: Driver processes ok query answers correctly
    Given connection open schema transaction for database: typedb
    When get answers of typeql schema query
      """
      define entity person;
      """
    Then answer type is: ok
    Then answer type is not: concept rows
    Then answer type is not: concept trees
    Then result is a successful ok
    Then transaction commits


    # TODO: Test optionals when introduced
  Scenario: Driver processes concept row query answers correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person owns name @key; attribute name, value string;
      """
    When get answers of typeql read query
      """
      match entity $p;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is read
    Then answer query type is not schema
    Then answer query type is not write
    Then answer size: 1
    Then answer column names are:
      | p |
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get entity type by index of variable(p) get label: person

    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is read
    Then answer query type is not schema
    Then answer query type is not write
    Then answer size: 1
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name

    When typeql schema query
      """
      define attribute age, value long;
      """
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is read
    Then answer query type is not schema
    Then answer query type is not write
    Then answer size: 2
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name
    Then answer get row(1) get entity type(p) get label: person
    Then answer get row(1) get attribute type(n) get label: age
    Then answer get row(1) get entity type by index of variable(p) get label: person
    Then answer get row(1) get attribute type by index of variable(n) get label: age
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is read
    Then answer query type is not schema
    Then answer query type is not write
    Then answer size: 2
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name
    Then answer get row(1) get entity type(p) get label: person
    Then answer get row(1) get attribute type(n) get label: age
    Then answer get row(1) get entity type by index of variable(p) get label: person
    Then answer get row(1) get attribute type by index of variable(n) get label: age

    When get answers of typeql read query
      """
      match $p isa person;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer size: 0

    When transaction closes
    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $p isa person, has name "John";
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is write
    Then answer query type is not schema
    Then answer query type is not read
    Then answer size: 1
    Then answer column names are:
      | p |
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get entity by index of variable(p) get type get label: person

    When get answers of typeql read query
      """
      match $p isa person, has name $a;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept trees
    Then answer query type is read
    Then answer query type is not schema
    Then answer query type is not write
    Then answer size: 1
    Then answer column names are:
      | p |
      | a |
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get entity by index of variable(p) get type get label: person
    Then answer get row(0) get attribute(a) get type get label: name
    Then answer get row(0) get attribute(a) get value is: "John"
    Then answer get row(0) get attribute by index of variable(a) get type get label: name
    Then answer get row(0) get attribute by index of variable(a) get value is: "John"
    Then transaction commits


  # TODO: Implement value groups checks
  #Scenario: Driver processes concept row query answers with value groups correctly


  # TODO: Implement concept trees checks
  #Scenario: Driver processes concept tree query answers correctly


  Scenario: Driver processes query errors correctly
    Given connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      """
    Then typeql schema query; fails
      """

      """
    Then typeql schema query; fails
      """

      """
    Then typeql read query; fails
      """
      match relation $r;
      """
    Then typeql schema query; fails
      """
      define entity entity;
      """
    Then typeql schema query; fails
      """
      define attribute name owns name;
      """


  ############
  # CONCEPTS #
  ############

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
    Then answer size: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is thing type: true
    Then answer get row(0) get variable(p) is thing: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: true
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false

    Then answer get row(0) get type(p) get label: person
    Then answer get row(0) get thing type(p) get label: person
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is thing type: true
    Then answer get row(0) get variable(p) is thing: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: true
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false

    Then answer get row(0) get type(p) get label: parentship
    Then answer get row(0) get thing type(p) get label: parentship
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(p) is type: true
    Then answer get row(0) get variable(p) is thing type: false
    Then answer get row(0) get variable(p) is thing: false
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: true
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false

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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is thing type: true
    Then answer get row(0) get variable(a) is thing: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false

    Then answer get row(0) get type(a) get label: untyped
    Then answer get row(0) get thing type(a) get label: untyped
    Then answer get row(0) get attribute type(a) get label: untyped

    Then answer get row(0) get attribute type(a) get value type: none
    Then answer get row(0) get attribute type(a) is untyped: true
    Then answer get row(0) get attribute type(a) is boolean: false
    Then answer get row(0) get attribute type(a) is long: false
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is thing type: true
    Then answer get row(0) get variable(a) is thing: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false

    Then answer get row(0) get type(a) get label: typed
    Then answer get row(0) get thing type(a) get label: typed
    Then answer get row(0) get attribute type(a) get label: typed

    Then answer get row(0) get attribute type(a) get value type: <value-type>
    Then answer get row(0) get attribute type(a) is untyped: false
    Then answer get row(0) get attribute type(a) is boolean: <is-boolean>
    Then answer get row(0) get attribute type(a) is long: <is-long>
    Then answer get row(0) get attribute type(a) is double: <is-double>
    Then answer get row(0) get attribute type(a) is decimal: <is-decimal>
    Then answer get row(0) get attribute type(a) is string: <is-string>
    Then answer get row(0) get attribute type(a) is date: <is-date>
    Then answer get row(0) get attribute type(a) is datetime: <is-datetime>
    Then answer get row(0) get attribute type(a) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get attribute type(a) is duration: <is-duration>
    Then answer get row(0) get attribute type(a) is struct: <is-struct>
    Examples:
      | value-type  | is-boolean | is-long | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration | is-struct |
      | boolean     | true       | false   | false     | false      | false     | false   | false       | false          | false       | false     |
      | long        | false      | true    | false     | false      | false     | false   | false       | false          | false       | false     |
      | double      | false      | false   | true      | false      | false     | false   | false       | false          | false       | false     |
      | decimal     | false      | false   | false     | true       | false     | false   | false       | false          | false       | false     |
      | string      | false      | false   | false     | false      | true      | false   | false       | false          | false       | false     |
      | date        | false      | false   | false     | false      | false     | true    | false       | false          | false       | false     |
      | datetime    | false      | false   | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime-tz | false      | false   | false     | false      | false     | false   | false       | true           | false       | false     |
      | duration    | false      | false   | false     | false      | false     | false   | false       | false          | true        | false     |


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
        reviews value long,
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(a) is type: true
    Then answer get row(0) get variable(a) is thing type: true
    Then answer get row(0) get variable(a) is thing: false
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: true
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: false

    Then answer get row(0) get type(a) get label: film
    Then answer get row(0) get thing type(a) get label: film
    Then answer get row(0) get attribute type(a) get label: film

    Then answer get row(0) get attribute type(a) get value type: film-properties
    Then answer get row(0) get attribute type(a) is untyped: false
    Then answer get row(0) get attribute type(a) is boolean: false
    Then answer get row(0) get attribute type(a) is long: false
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(p) is type: false
    Then answer get row(0) get variable(p) is thing type: false
    Then answer get row(0) get variable(p) is thing: true
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: true
    Then answer get row(0) get variable(p) is relation: false
    Then answer get row(0) get variable(p) is attribute: false

    Then answer get row(0) get thing(p) get type get label: person
    Then answer get row(0) get entity(p) get iid exists
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(p) is type: false
    Then answer get row(0) get variable(p) is thing type: false
    Then answer get row(0) get variable(p) is thing: true
    Then answer get row(0) get variable(p) is value: false
    Then answer get row(0) get variable(p) is entity type: false
    Then answer get row(0) get variable(p) is relation type: false
    Then answer get row(0) get variable(p) is attribute type: false
    Then answer get row(0) get variable(p) is role type: false
    Then answer get row(0) get variable(p) is entity: false
    Then answer get row(0) get variable(p) is relation: true
    Then answer get row(0) get variable(p) is attribute: false

    Then answer get row(0) get thing(p) get type get label: parentship
    Then answer get row(0) get relation(p) get iid exists
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
    Then answer query type is read
    Then answer size: 1

    Then answer get row(0) get variable(a) is type: false
    Then answer get row(0) get variable(a) is thing type: false
    Then answer get row(0) get variable(a) is thing: true
    Then answer get row(0) get variable(a) is value: false
    Then answer get row(0) get variable(a) is entity type: false
    Then answer get row(0) get variable(a) is relation type: false
    Then answer get row(0) get variable(a) is attribute type: false
    Then answer get row(0) get variable(a) is role type: false
    Then answer get row(0) get variable(a) is entity: false
    Then answer get row(0) get variable(a) is relation: false
    Then answer get row(0) get variable(a) is attribute: true

    Then answer get row(0) get thing(a) get type get label: typed
    Then answer get row(0) get attribute(a) get type get label: typed
    Then answer get row(0) get attribute(a) get type is attribute: false
    Then answer get row(0) get attribute(a) get type is entity type: false
    Then answer get row(0) get attribute(a) get type is relation type: false
    Then answer get row(0) get attribute(a) get type is attribute type: true
    Then answer get row(0) get attribute(a) get type is role type: false

    Then answer get row(0) get attribute(a) get type get value type: <value-type>
    Then answer get row(0) get attribute(a) is boolean: <is-boolean>
    Then answer get row(0) get attribute(a) is long: <is-long>
    Then answer get row(0) get attribute(a) is double: <is-double>
    Then answer get row(0) get attribute(a) is decimal: <is-decimal>
    Then answer get row(0) get attribute(a) is string: <is-string>
    Then answer get row(0) get attribute(a) is date: <is-date>
    Then answer get row(0) get attribute(a) is datetime: <is-datetime>
    Then answer get row(0) get attribute(a) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get attribute(a) is duration: <is-duration>
    Then answer get row(0) get attribute(a) is struct: false
    Then answer get row(0) get attribute(a) get value is: <value>
    Then answer get row(0) get attribute(a) as <value-type> is: <value>
    Then answer get row(0) get attribute(a) get value is not: <not-value>
    Then answer get row(0) get attribute(a) as <value-type> is not: <not-value>
    Examples:
      | value-type  | value                                       | not-value                                    | is-boolean | is-long | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration |
      | boolean     | true                                        | false                                        | true       | false   | false     | false      | false     | false   | false       | false          | false       |
      | long        | 12345090                                    | 0                                            | false      | true    | false     | false      | false     | false   | false       | false          | false       |
      | double      | 0.0000000000000000001                       | 0.000000000000000001                         | false      | false   | true      | false      | false     | false   | false       | false          | false       |
      | double      | 2.01234567                                  | 2.01234568                                   | false      | false   | true      | false      | false     | false   | false       | false          | false       |
      | decimal     | 1234567890.0001234567890                    | 1234567890.001234567890                      | false      | false   | false     | true       | false     | false   | false       | false          | false       |
      | decimal     | 0.0000000000000000001                       | 0.000000000000000001                         | false      | false   | false     | true       | false     | false   | false       | false          | false       |
      | string      | "John \"Baba Yaga\" Wick"                   | "John Baba Yaga Wick"                        | false      | false   | false     | false      | true      | false   | false       | false          | false       |
      | date        | 2024-09-20                                  | 2025-09-20                                   | false      | false   | false     | false      | false     | true    | false       | false          | false       |
      | datetime    | 1999-02-26T12:15:05                         | 1999-02-26T12:15:00                          | false      | false   | false     | false      | false     | false   | true        | false          | false       |
      | datetime    | 1999-02-26T12:15:05.000000001               | 1999-02-26T12:15:05.00000001                 | false      | false   | false     | false      | false     | false   | true        | false          | false       |
      | datetime-tz | 2024-09-20T16:40:05 America/New_York        | 2024-06-20T15:40:05 America/New_York         | false      | false   | false     | false      | false     | false   | false       | true           | false       |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | 2024-09-20T16:40:05.000000001 Europe/Belfast | false      | false   | false     | false      | false     | false   | false       | true           | false       |
      # TODO: Add datetime-tz with offsets
      | duration    | P1Y10M7DT15H44M5.00394892S                  | P1Y10M7DT15H44M5.0394892S                    | false      | false   | false     | false      | false     | false   | false       | false          | true        |
      | duration    | P66W                                        | P67W                                         | false      | false   | false     | false      | false     | false   | false       | false          | true        |


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
#        reviews value long,
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
#    Then answer query type is read
#    Then answer size: 1
#
#    Then answer get row(0) get variable(f) is type: false
#    Then answer get row(0) get variable(f) is thing type: false
#    Then answer get row(0) get variable(f) is thing: true
#    Then answer get row(0) get variable(f) is value: false
#    Then answer get row(0) get variable(f) is entity type: false
#    Then answer get row(0) get variable(f) is relation type: false
#    Then answer get row(0) get variable(f) is attribute type: false
#    Then answer get row(0) get variable(f) is role type: false
#    Then answer get row(0) get variable(f) is entity: false
#    Then answer get row(0) get variable(f) is relation: false
#    Then answer get row(0) get variable(f) is attribute: true
#
#    Then answer get row(0) get thing(f) get type get label: typed
#    Then answer get row(0) get attribute(f) get type get label: typed
#    Then answer get row(0) get attribute(f) get type is attribute: false
#    Then answer get row(0) get attribute(f) get type is entity type: false
#    Then answer get row(0) get attribute(f) get type is relation type: true
#    Then answer get row(0) get attribute(f) get type is attribute type: true
#    Then answer get row(0) get attribute(f) get type is role type: false
#
#    Then answer get row(0) get attribute(f) get type get value type: film-properties
#    Then answer get row(0) get attribute(f) is boolean: false
#    Then answer get row(0) get attribute(f) is long: false
#    Then answer get row(0) get attribute(f) is double: false
#    Then answer get row(0) get attribute(f) is decimal: false
#    Then answer get row(0) get attribute(f) is string: false
#    Then answer get row(0) get attribute(f) is date: false
#    Then answer get row(0) get attribute(f) is datetime: false
#    Then answer get row(0) get attribute(f) is datetime-tz: false
#    Then answer get row(0) get attribute(f) is duration: false
#    Then answer get row(0) get attribute(f) is struct: true
#    Then answer get row(0) get attribute(f) get value is: <value>
#    Then answer get row(0) get attribute(f) as <value-type> is: <value>
#    Then answer get row(0) get attribute(f) get value is not: <value>
#    Then answer get row(0) get attribute(f) as <value-type> is not: <not-value>


  # TODO: Implement value variables
#  Scenario Outline: Driver processes values of type <value-type> correctly
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define entity person, owns typed; attribute typed, value <value-type>;
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    Given typeql write query
#      """
#      insert $p isa person, has typed <value>;
#      """
#    When get answers of typeql read query
#      """
#      match $_ isa person, has typed $v;
#      $value = $v;
#      """
#    Then answer type is: concept rows
#    Then answer query type is read
#    Then answer size: 1
#
#    Then answer get row(0) get variable(value) is type: false
#    Then answer get row(0) get variable(value) is thing type: false
#    Then answer get row(0) get variable(value) is thing: false
#    Then answer get row(0) get variable(value) is value: true
#    Then answer get row(0) get variable(value) is entity type: false
#    Then answer get row(0) get variable(value) is relation type: false
#    Then answer get row(0) get variable(value) is attribute type: false
#    Then answer get row(0) get variable(value) is role type: false
#    Then answer get row(0) get variable(value) is entity: false
#    Then answer get row(0) get variable(value) is relation: false
#    Then answer get row(0) get variable(value) is attribute: false
#
#    Then answer get row(0) get value(value) get value type: <value-type>
#    Then answer get row(0) get value(value) is boolean: <is-boolean>
#    Then answer get row(0) get value(value) is long: <is-long>
#    Then answer get row(0) get value(value) is double: <is-double>
#    Then answer get row(0) get value(value) is decimal: <is-decimal>
#    Then answer get row(0) get value(value) is string: <is-string>
#    Then answer get row(0) get value(value) is date: <is-date>
#    Then answer get row(0) get value(value) is datetime: <is-datetime>
#    Then answer get row(0) get value(value) is datetime-tz: <is-datetime-tz>
#    Then answer get row(0) get value(value) is duration: <is-duration>
#    Then answer get row(0) get value(value) is struct: false
#    Then answer get row(0) get value(value) get is: <value>
#    Then answer get row(0) get value(value) as <value-type> is: <value>
#    Then answer get row(0) get value(value) get is not: <not-value>
#    Then answer get row(0) get value(value) as <value-type> is not: <not-value>
#    Examples:
#      | value-type  | value                                       | not-value                                    | is-boolean | is-long | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration |
#      | boolean     | true                                        | false                                        | true       | false   | false     | false      | false     | false   | false       | false          | false       |
#      | long        | 12345090                                    | 0                                            | false      | true    | false     | false      | false     | false   | false       | false          | false       |
#      | double      | 0.0000000000000000001                       | 0.000000000000000001                         | false      | false   | true      | false      | false     | false   | false       | false          | false       |
#      | double      | 2.01234567                                  | 2.01234568                                   | false      | false   | true      | false      | false     | false   | false       | false          | false       |
#      | decimal     | 1234567890.0001234567890                    | 1234567890.001234567890                      | false      | false   | false     | true       | false     | false   | false       | false          | false       |
#      | decimal     | 0.0000000000000000001                       | 0.000000000000000001                         | false      | false   | false     | true       | false     | false   | false       | false          | false       |
#      | string      | "John \"Baba Yaga\" Wick"                   | "John Baba Yaga Wick"                        | false      | false   | false     | false      | true      | false   | false       | false          | false       |
#      | date        | 2024-09-20                                  | 2025-09-20                                   | false      | false   | false     | false      | false     | true    | false       | false          | false       |
#      | datetime    | 1999-02-26T12:15:05                         | 1999-02-26T12:15:00                          | false      | false   | false     | false      | false     | false   | true        | false          | false       |
#      | datetime    | 1999-02-26T12:15:05.000000001               | 1999-02-26T12:15:05.00000001                 | false      | false   | false     | false      | false     | false   | true        | false          | false       |
#      | datetime-tz | 2024-09-20T16:40:05 America/New_York        | 2024-06-20T15:40:05 America/New_York         | false      | false   | false     | false      | false     | false   | false       | true           | false       |
#      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | 2024-09-20T16:40:05.000000001 Europe/Belfast | false      | false   | false     | false      | false     | false   | false       | true           | false       |
#      # TODO: Add datetime-tz with offsets
#      | duration    | P1Y10M7DT15H44M5.00394892S                  | P1Y10M7DT15H44M5.0394892S                    | false      | false   | false     | false      | false     | false   | false       | false          | true        |
#      | duration    | P66W                                        | P67W                                         | false      | false   | false     | false      | false     | false   | false       | false          | true        |


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
#        reviews value long,
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
#    Then answer query type is read
#    Then answer size: 1
#
#    Then answer get row(0) get variable(v) is type: false
#    Then answer get row(0) get variable(v) is thing type: false
#    Then answer get row(0) get variable(v) is thing: false
#    Then answer get row(0) get variable(v) is value: true
#    Then answer get row(0) get variable(v) is entity type: false
#    Then answer get row(0) get variable(v) is relation type: false
#    Then answer get row(0) get variable(v) is attribute type: false
#    Then answer get row(0) get variable(v) is role type: false
#    Then answer get row(0) get variable(v) is entity: false
#    Then answer get row(0) get variable(v) is relation: false
#    Then answer get row(0) get variable(v) is attribute: false
#
#    Then answer get row(0) get value(v) get value type: <value-type>
#    Then answer get row(0) get value(v) is boolean: <is-boolean>
#    Then answer get row(0) get value(v) is long: <is-long>
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
      insert $dt 2023-05-01T00:00:00 isa dt;
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
      insert $dt 2023-05-01T00:00:00 Asia/Calcutta isa dt;
      """
    Then answer get row(0) get attribute(dt) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(dt) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(dt) get value is not: 2023-05-01T00:00:00 America/Chicago
    Then answer get row(0) get attribute(dt) get value is not: 2023-04-30T13:30:00 America/Chicago

    When get answers of typeql read query
      """
      match $x isa dt;
      """
    Then answer get row(0) get attribute(x) get value is: 2023-05-01T00:00:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 Asia/Calcutta
    Then answer get row(0) get attribute(x) get value is not: 2023-05-01T00:00:00 America/Chicago
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 America/Chicago
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
    Then answer get row(0) get attribute(x) get value is not: 2023-04-30T13:30:00 America/Chicago
