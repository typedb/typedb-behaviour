# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Connection Transaction

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database

  Scenario: one database, one transaction to read
    When connection create database: typedb
    Given connection opens read transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: read

  Scenario: one database, one transaction to write
    When connection create database: typedb
    Given connection opens write transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: write

  Scenario: one database, one committed write transaction is closed
    When connection create database: typedb
    Given connection opens write transaction for database: typedb
    Then transaction commits
    Then transaction commits; throws exception

  Scenario: one database, transaction close is idempotent
    When connection create database: typedb
    Given connection open write transaction for database: typedb
    Then transaction closes
    Then transaction is open: false
    Then transaction closes
    Then transaction is open: false

  @ignore-typedb
  Scenario: one database, many transactions to read
    When connection create database: typedb
    When open transactions of type:
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
    Then transactions are null: false
    Then transactions are open: true
    Then transactions have type:
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |

  @ignore-typedb
  Scenario: one database, many transactions to write
    When connection create database: typedb
    When open transactions of type:
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
    Then transactions are null: false
    Then transactions are open: true
    Then transactions have type:
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |

  @ignore-typedb
  Scenario: one database, many transactions to read and write
    When connection create database: typedb
    When open transactions of type:
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
    Then transactions are null: false
    Then transactions are open: true
    Then transactions have type:
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |

  Scenario: one database, many transactions in parallel to read
    When connection create database: typedb
    When open transactions in parallel of type:
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
    Then transactions in parallel are null: false
    Then transactions in parallel are open: true
    Then transactions in parallel have type:
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |
      | read |

  Scenario: one database, many transactions in parallel to write
    When connection create database: typedb
    When open transactions in parallel of type:
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
    Then transactions in parallel are null: false
    Then transactions in parallel are open: true
    Then transactions in parallel have type:
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |
      | write |

  Scenario: one database, many transactions in parallel to read and write
    When connection create database: typedb
    When open transactions in parallel of type:
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
    Then transactions in parallel are null: false
    Then transactions in parallel are open: true
    Then transactions in parallel have type:
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |
      | read  |
      | write |

  Scenario: write in a read transaction throws
    When connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql define
      """
      define person sub entity;
      """
    Given transaction commits
    Given connection open read transaction for database: typedb
     # TODO: 3.0: Message update for 3.0
    Given typeql insert; throws exception containing "transaction type does not allow"
      """
      insert $person isa entity;
      """

  Scenario: commit in a read transaction throws
    When connection create database: typedb
    Given connection open read transaction for database: typedb
    Then transaction commits; throws exception

  Scenario: schema modification in a write transaction throws
    When connection create database: typedb
    Given connection open write transaction for database: typedb
    # TODO: 3.0: Message update for 3.0
    Then typeql define; throws exception containing "transaction type does not allow"
      """
      define person sub entity;
      """

  Scenario: write data in a schema transaction throws
    When connection create database: typedb
    Given connection open schema transaction for database: typedb
    Then typeql define
      """
      define person sub entity;
      """
    # TODO: Message update for 3.0
    Then typeql insert; throws exception containing "transaction type does not allow"
      """
      insert $x isa person;
      """

  @ignore-typedb
  Scenario: transaction timeouts are configurable
    When connection create database: typedb
    Then set session option session-idle-timeout-millis to: 20000
    Given connection open schema session for database: typedb
    Given set transaction option transaction-timeout-millis to: 10000
    When session opens transaction of type: write
    Then wait 8 seconds
    Then typeql define
      """
      define person sub entity;
      """
    Then wait 4 seconds
    Then typeql define; throws exception containing "Transaction exceeded maximum configured duration"
      """
      define person sub entity;
      """
