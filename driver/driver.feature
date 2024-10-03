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
    When connection opens with a wrong address; fails
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

  Scenario: Driver can delete non-existing database
    Given connection does not have database: does-not-exist
    When connection delete database: does-not-exist
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


  Scenario: Driver can acquire database schema
    Given connection has database: typedb
    Then connection get database(typedb) has schema:
    """
    """
    Then connection get database(typedb) has type schema:
    """
    """

    When connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
    entity person @abstract, owns age @card(1..1);
    attribute age, value long @range(0..150);
    """
    Then connection get database(typedb) has schema:
    """
    """
    Then connection get database(typedb) has type schema:
    """
    """
    When transaction commits
    Then connection get database(typedb) has schema:
    """
    define
    entity person @abstract, owns age @card(1..1);
    attribute age, value long @range(0..150);
    """
    Then connection get database(typedb) has type schema:
    """
    define
    entity person @abstract, owns age @card(1..1);
    attribute age, value long @range(0..150);
    """

    When connection open schema transaction for database: typedb
    When typeql schema query
    """
    redefine
    attribute age, value long @range(0..);
    """
    When typeql schema query
    """
    define
    entity person owns age @range(0..150);
    entity fictional-character owns age;
    """
    Then connection get database(typedb) has schema:
    """
    define
    entity person @abstract, owns age @card(1..1);
    attribute age, value long @range(0..150);
    """
    Then connection get database(typedb) has type schema:
    """
    define
    entity person @abstract, owns age @card(1..1);
    attribute age, value long @range(0..150);
    """
    When transaction commits
    Then connection get database(typedb) has schema:
    """
    define
    entity person @abstract, owns age @card(1..1) @range(0..150);
    entity fictional-character owns age;
    attribute age, value long @range(0..);
    """
    Then connection get database(typedb) has type schema:
    """
    define
    entity person @abstract, owns age @card(1..1) @range(0..150);
    entity fictional-character owns age;
    attribute age, value long @range(0..);
    """

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


  Scenario: Driver can rollback transactions of schema and write types, cannot rollback transaction of type read
    When connection open schema transaction for database: typedb
    Then transaction has type: schema
    Then transaction is open: true
    When transaction rollbacks
    Then transaction is open: false

    When connection open write transaction for database: typedb
    Then transaction has type: write
    Then transaction is open: true
    When transaction rollbacks
    Then transaction is open: false

    When connection open read transaction for database: typedb
    Then transaction has type: read
    Then transaction is open: true
    Then transaction rollbacks; fails
    Then transaction is open: false


  # TODO: Check options setting and retrieval


  Scenario: Driver can schedule "transaction on close" jobs
    Given connection does not have database: created-after-schema
    Given connection does not have database: created-after-write
    Given connection does not have database: created-after-read
    When connection open schema transaction for database: typedb
    When schedule database creation on transaction close: created-after-schema
    Then connection does not have database: created-after-schema
    Then connection does not have database: created-after-write
    Then connection does not have database: created-after-read
    When transaction closes
    Then connection has database: created-after-schema
    Then connection does not have database: created-after-write
    Then connection does not have database: created-after-read

    When connection open write transaction for database: typedb
    Then connection has database: created-after-schema
    Then connection does not have database: created-after-write
    Then connection does not have database: created-after-read
    When transaction closes
    Then connection has database: created-after-schema
    Then connection does not have database: created-after-write
    Then connection does not have database: created-after-read

    When connection open write transaction for database: typedb
    When schedule database creation on transaction close: created-after-write
    Then connection has database: created-after-schema
    Then connection does not have database: created-after-write
    Then connection does not have database: created-after-read
    When transaction closes
    Then connection has database: created-after-schema
    Then connection has database: created-after-write
    Then connection does not have database: created-after-read

    When connection open read transaction for database: typedb
    When schedule database creation on transaction close: created-after-read
    Then connection has database: created-after-schema
    Then connection has database: created-after-write
    Then connection does not have database: created-after-read
    When transaction closes
    Then connection has database: created-after-schema
    Then connection has database: created-after-write
    Then connection has database: created-after-read


  Scenario: Driver processes transaction commit errors correctly
    Given connection open schema transaction for database: typedb
    When get answers of typeql schema query; fails
      """
      define attribute name;
      """
    Then transaction commits; fails

  ###########
  # QUERIES #
  ###########

  Scenario: Driver processes ok query answers correctly
    Given connection open schema transaction for database: typedb
    When get answers of typeql schema query
      """
      define entity person;
      """
    Then answer type: ok
    Then answer size: 1
    Then result is a successful ok
    Then transaction commits


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
    Then answer type: concept rows
    Then answer size: 1
    Then result is a single row with variable 'p': person

    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type: concept rows
    Then uniquely identify answer concepts
      | p      | n    |
      | person | name |

    When typeql schema query
      """
      define attribute age, value long;
      """
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type: concept rows
    Then answer size: 2
    Then uniquely identify answer concepts
      | p      | n    |
      | person | name |
      | person | age  |
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type: concept rows
    Then answer size: 2
    Then uniquely identify answer concepts
      | p      | n    |
      | person | name |
      | person | age  |
    Then transaction commits

    When get answers of typeql read query
      """
      match relation $r;
      """
    Then answer type: concept rows
    Then answer size: 0

    When transaction closes
    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert person $p, has name "John";
      """
    Then answer type: concept rows
    Then answer size: 1
    Then uniquely identify answer concepts
      | p      |
      | person |

    When get answers of typeql read query
      """
      match $p isa person, has name $n;
      """
    Then answer type: concept rows
    Then answer size: 1
    Then uniquely identify answer concepts
      | p      | n      |
      | person | "John" |
    Then transaction commits


  # TODO: Implement value groups checks
  #Scenario: Driver processes concept row query answers with value groups correctly


  # TODO: Implement concept trees checks
  #Scenario: Driver processes concept tree query answers correctly


  Scenario: Driver processes query errors correctly
    Given connection open schema transaction for database: typedb
    Then get answers of typeql schema query; fails
      """
      """
    Then get answers of typeql schema query; fails
      """

      """
    Then get answers of typeql schema query; fails
      """

      """
    Then get answers of typeql schema query; fails
      """
      define entity entity;
      """
    Then get answers of typeql schema query; fails
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
    Then answer type: concept rows
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
    Then answer get row(0) get entity type(p) get name: person
    Then answer get row(0) get entity type(p) get scope is none


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
    Then answer type: concept rows
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
    Then answer get row(0) get relation type(p) get name: parentship
    Then answer get row(0) get relation type(p) get scope is none


  Scenario: Driver processes role types correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define relation parentship, relates parent;
      """
    When get answers of typeql read query
      """
      match relation parentship, relates $p;
      """
    Then answer type: concept rows
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
    Then answer get row(0) get role type(p) get name: parent
    Then answer get row(0) get role type(p) get scope: parentship


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
    Then answer type: concept rows
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
    Then answer get row(0) get attribute type(a) get name: untyped
    Then answer get row(0) get attribute type(a) get scope is none

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
    Then answer type: concept rows
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
    Then answer get row(0) get attribute type(a) get name: typed
    Then answer get row(0) get attribute type(a) get scope is none

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
      | struct      | false      | false   | false     | false      | false     | false   | false       | false          | false       | true      |


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
    Then answer type: concept rows
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
    Then answer type: concept rows
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
    Then answer type: concept rows
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
    Then answer get row(0) get attribute(a) get type is relation type: true
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
    Then answer get row(0) get attribute(a) is struct: <is-struct>
    Then answer get row(0) get attribute(a) get <value-type> value: <value>
    Examples:
      | value-type  | value                                       | is-boolean | is-long | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration | is-struct |
      | boolean     | true                                        | true       | false   | false     | false      | false     | false   | false       | false          | false       | false     |
      | long        | 12345090                                    | false      | true    | false     | false      | false     | false   | false       | false          | false       | false     |
      | double      | 2.01234567                                  | false      | false   | true      | false      | false     | false   | false       | false          | false       | false     |
      | decimal     | 1234567890.0001234567890                    | false      | false   | false     | true       | false     | false   | false       | false          | false       | false     |
      | string      | "John \"Baba Yaga\" Wick"                   | false      | false   | false     | false      | true      | false   | false       | false          | false       | false     |
      | date        | 2024-09-20                                  | false      | false   | false     | false      | false     | true    | false       | false          | false       | false     |
      | datetime    | 1999-02-26T12:15:05                         | false      | false   | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime    | 1999-02-26T12:15:05.000000001               | false      | false   | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime-tz | 2024-09-20T16:40:05 Europe/London           | false      | false   | false     | false      | false     | false   | false       | true           | false       | false     |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | false      | false   | false     | false      | false     | false   | false       | true           | false       | false     |
      | duration    | P1Y10M7DT15H44M5.00394892S                  | false      | false   | false     | false      | false     | false   | false       | false          | true        | false     |
  # TODO: Implement structs
#      | struct      |                                             | false      | false   | false     | false      | false     | false   | false       | false          | false       | true      |


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
      """
    Then answer type: concept rows
    Then answer size: 1

    Then answer get row(0) get variable(v) is type: false
    Then answer get row(0) get variable(v) is thing type: false
    Then answer get row(0) get variable(v) is thing: false
    Then answer get row(0) get variable(v) is value: true
    Then answer get row(0) get variable(v) is entity type: false
    Then answer get row(0) get variable(v) is relation type: false
    Then answer get row(0) get variable(v) is attribute type: false
    Then answer get row(0) get variable(v) is role type: false
    Then answer get row(0) get variable(v) is entity: false
    Then answer get row(0) get variable(v) is relation: false
    Then answer get row(0) get variable(v) is attribute: false

    Then answer get row(0) get value(v) get value type: <value-type>
    Then answer get row(0) get value(v) is boolean: <is-boolean>
    Then answer get row(0) get value(v) is long: <is-long>
    Then answer get row(0) get value(v) is double: <is-double>
    Then answer get row(0) get value(v) is decimal: <is-decimal>
    Then answer get row(0) get value(v) is string: <is-string>
    Then answer get row(0) get value(v) is date: <is-date>
    Then answer get row(0) get value(v) is datetime: <is-datetime>
    Then answer get row(0) get value(v) is datetime-tz: <is-datetime-tz>
    Then answer get row(0) get value(v) is duration: <is-duration>
    Then answer get row(0) get value(v) is struct: <is-struct>
    Then answer get row(0) get value(v) get: <value>
    Then answer get row(0) get value(v) as <value-type>: <value>
    Examples:
      | value-type  | value                                       | is-boolean | is-long | is-double | is-decimal | is-string | is-date | is-datetime | is-datetime-tz | is-duration | is-struct |
      | boolean     | true                                        | true       | false   | false     | false      | false     | false   | false       | false          | false       | false     |
      | long        | 12345090                                    | false      | true    | false     | false      | false     | false   | false       | false          | false       | false     |
      | double      | 2.01234567                                  | false      | false   | true      | false      | false     | false   | false       | false          | false       | false     |
      | decimal     | 1234567890.0001234567890                    | false      | false   | false     | true       | false     | false   | false       | false          | false       | false     |
      | string      | "John \"Baba Yaga\" Wick"                   | false      | false   | false     | false      | true      | false   | false       | false          | false       | false     |
      | date        | 2024-09-20                                  | false      | false   | false     | false      | false     | true    | false       | false          | false       | false     |
      | datetime    | 1999-02-26T12:15:05                         | false      | false   | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime    | 1999-02-26T12:15:05.000000001               | false      | false   | false     | false      | false     | false   | true        | false          | false       | false     |
      | datetime-tz | 2024-09-20T16:40:05 Europe/London           | false      | false   | false     | false      | false     | false   | false       | true           | false       | false     |
      | datetime-tz | 2024-09-20T16:40:05.000000001 Europe/London | false      | false   | false     | false      | false     | false   | false       | true           | false       | false     |
      | duration    | P1Y10M7DT15H44M5.00394892S                  | false      | false   | false     | false      | false     | false   | false       | false          | true        | false     |
  # TODO: Implement structs
#      | struct      |                                             | false      | false   | false     | false      | false     | false   | false       | false          | false       | true      |
