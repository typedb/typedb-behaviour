# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required connection functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Connection

  Background: Open connection, create driver, create database
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
    When connection opens with a wrong host; fails with a message containing: "failed to lookup address information"
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

  #############
  # DATABASES #
  #############

  # TODO: Explicitly test "databases().all()" interfaces. Make sure that "has" uses "contains" in drivers instead.

  Scenario: Driver cannot delete non-existing database
    Given connection does not have database: does-not-exist
    Then connection delete database: does-not-exist; fails with a message containing: "Database 'does-not-exist' not found"
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
    define
    """
    Then connection get database(typedb) has type schema:
    """
    """

    When connection open schema transaction for database: typedb
    When typeql schema query
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
    Then connection get database(typedb) has schema:
    """
    define
    """
    Then connection get database(typedb) has type schema:
    """
    define
    """
    When transaction commits
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
    Then connection get database(typedb) has type schema:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..150);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;
    """

    When connection open schema transaction for database: typedb
    When typeql schema query
    """
    redefine
      attribute age value integer @range(0..);

      fun age($person: real-person) -> age:
        match
          $person has age $age;
        return first $age;
    """
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
    Then connection get database(typedb) has type schema:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..150);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;
    """

    When transaction commits
    Then connection get database(typedb) has schema:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;

      fun age($person: real-person) -> age:
        match
          $person has age $age;
        return first $age;
    """
    Then connection get database(typedb) has type schema:
    """
    define
      entity person @abstract, owns age @card(1..1);
      entity real-person sub person;
      entity not-real-person @abstract, sub person;
      attribute age, value integer @range(0..);
      relation friendship, relates friend;
      relation best-friendship sub friendship, relates best-friend as friend;
    """


  Scenario: Driver sees databases updates done by other drivers in background
    Then connection does not have database: newbie
    Then connection open schema transaction for database: newbie; fails with a message containing: "Database 'newbie' not found"
    # Consider refactoring of how we manage multiple drivers
    # if we use "background" steps more not to duplicate everything
    When in background, connection create database: newbie
    Then connection has databases:
      | newbie |
      | typedb |
    Then connection open schema transaction for database: newbie
    Then transaction commits
    When connection closes

    When connection opens with default authentication
    Then connection has databases:
      | newbie |
      | typedb |
    Then connection open schema transaction for database: newbie
    When transaction closes
    Then connection has databases:
      | newbie |
      | typedb |

    When in background, connection delete database: newbie
    Then connection does not have database: newbie
    Then connection open schema transaction for database: newbie; fails with a message containing: "Database 'newbie' not found"
    When connection closes

    When connection opens with default authentication
    Then connection does not have database: newbie
    Then connection open schema transaction for database: newbie; fails with a message containing: "Database 'newbie' not found"


  Scenario: Driver processes database management errors correctly
    Given connection open schema transaction for database: typedb
    Then connection create database with empty name; fails with a message containing: "is not a valid database name"

  ###############
  # TRANSACTION #
  ###############

  Scenario: Driver cannot open transaction to non-existing database
    Given connection does not have database: does-not-exist
    Then transaction is open: false
    Then connection open schema transaction for database: does-not-exist; fails with a message containing: "Database 'does-not-exist' not found"
    Then transaction is open: false
    Then connection open write transaction for database: does-not-exist; fails with a message containing: "Database 'does-not-exist' not found"
    Then transaction is open: false
    Then connection open read transaction for database: does-not-exist; fails with a message containing: "Database 'does-not-exist' not found"
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
    Then transaction commits; fails with a message containing: "Read transactions cannot be committed"
    Then transaction is open: false


  Scenario: Driver can rollback transactions of schema and write types, cannot rollback transaction of type read
    When connection open schema transaction for database: typedb
    Then transaction has type: schema
    Then transaction is open: true
    When transaction rollbacks
    Then transaction is open: true

    When transaction closes
    When connection open write transaction for database: typedb
    Then transaction has type: write
    Then transaction is open: true
    When transaction rollbacks
    Then transaction is open: true

    When transaction closes
    When connection open read transaction for database: typedb
    Then transaction has type: read
    Then transaction is open: true
    Then transaction rollbacks; fails with a message containing: "Read transactions cannot be rolled back"
    Then transaction is open: false


  Scenario Outline: Driver can open <type> transactions with different transaction timeouts
    When set transaction option transaction_timeout_millis to: 6000
    Then transaction is open: false
    When connection open <type> transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: <type>
    When wait 3 seconds
    Then transaction is open: true
    Then transaction has type: <type>
    Then typeql read query
      """
      match entity $x;
      """
    When wait 4 seconds
    Then transaction is open: false
    Then typeql read query; fails
      """
      match entity $x;
      """
    Examples:
      | type   |
      | schema |
      | write  |
      | read   |


  Scenario: Driver can open a schema transaction when a parallel schema lock is released
    When set transaction option transaction_timeout_millis to: 5000
    When set transaction option schema_lock_acquire_timeout_millis to: 1000
    When in background, connection open schema transaction for database: typedb
    Then transaction is open: false
    Then connection open schema transaction for database: typedb; fails with a message containing: "timeout"
    Then transaction is open: false
    When wait 5 seconds
    When set transaction option transaction_timeout_millis to: 1000
    When set transaction option schema_lock_acquire_timeout_millis to: 5000
    When in background, connection open schema transaction for database: typedb
    Then transaction is open: false
    When connection open schema transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: schema
    Then typeql read query
      """
      match entity $x;
      """


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

# TODO: Test on_close with planned driver's closing on transaction close (similar to old networking_in_on_close in Rust)

  Scenario: Driver processes transaction commit errors correctly
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define attribute name;
      """
    Then transaction commits; fails with a message containing: "Schema transaction commit failed"


  # TODO: check errors on transaction commits with callbacks (on_close) set!


  Scenario: Driver processes multiple failing schema and write transactions correctly
    Given connection open schema transaction for database: typedb
    When typeql schema query; fails
      """
      define entity new-entity sub unknown-entity;
      """
    Then transaction is open: false

    Then connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define entity new-entity sub unknown-entity;
      """
    Then transaction is open: false

    Then connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define entity new-entity;
      """
    Then transaction is open: true
    Then transaction commits

    When connection open write transaction for database: typedb
    When typeql write query; fails
      """
      insert $e isa unknown-entity;
      """

    Then connection open write transaction for database: typedb
    Then typeql write query
      """
      insert $e isa new-entity;
      """
    Then transaction commits

    Then connection open schema transaction for database: typedb
    Then typeql schema query; fails
      """
      define new-entity sub unknown-entity;
      """

    Then connection open write transaction for database: typedb
    Then typeql write query
      """
      insert $e isa new-entity;
      """
