# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Connection Transaction

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases

  Scenario Outline: one database, one <type> transaction
    When connection create database: typedb
    Given connection open <type> transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: <type>
    Examples:
      | type   |
      | read   |
      | write  |
      | schema |

  Scenario Outline: one database, one committed <type> transaction is closed
    When connection create database: typedb
    Given connection open <type> transaction for database: typedb
    Then transaction commits
    Then transaction is open: false
    Examples:
      | type   |
      | write  |
      | schema |

  Scenario: read transaction cannot be committed
    When connection create database: typedb
    Given connection open read transaction for database: typedb
    Then transaction commits; fails

  Scenario Outline: one database, <type> transaction close
    When connection create database: typedb
    Given connection open <type> transaction for database: typedb
    Then transaction closes
    Then transaction is open: false
    Examples:
      | type   |
      | read   |
      | write  |
      | schema |

    # TODO: Fix rollback
#  Scenario Outline: one database, <type> transaction rollback
#    When connection create database: typedb
#    Given connection open <type> transaction for database: typedb
#    Then transaction rollbacks
#    Then transaction is open: true
#    Examples:
#      | type   |
#      | write  |
#      | schema |

  Scenario: read transaction cannot be rollbacked
    When connection create database: typedb
    Given connection open read transaction for database: typedb
    Then transaction rollbacks; fails

  @ignore-typedb
  Scenario: one database, many <type> transactions
    When connection create database: typedb
    When connection open transactions for database: typedb, of type:
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
    Then transactions are open: true
    Then transactions have type:
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
      | <type> |
    Examples:
      | type   |
      | read   |
      | write  |
      | schema |

  @ignore-typedb
  Scenario: one database, many transactions of different types
    When connection create database: typedb
    When connection open transactions for database: typedb, of type:
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
    Then transactions are open: true
    Then transactions have type:
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |
      | read   |
      | write  |
      | schema |

    # TODO: Fix parallel execution for the server
#  Scenario Outline: one database, many <type> transactions in parallel
#    When connection create database: typedb
#    When connection open transactions in parallel for database: typedb, of type:
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type:
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#      | <type> |
#    Examples:
#      | type   |
#      | read   |
#      | write  |
#      | schema |

    # TODO: Fix parallel execution for the server
#  Scenario: one database, many transactions in parallel of different types
#    When connection create database: typedb
#    When connection open transactions in parallel for database: typedb, of type:
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type:
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |
#      | read   |
#      | write  |
#      | schema |

  Scenario Outline: write in a <type> transaction fails
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    Given transaction commits
    When connection open <type> transaction for database: typedb
    Then typeql write query; fails
      """
      insert $person isa person;
      """
    Examples:
      | type   |
      | read   |

  Scenario: commit in a read transaction fails
    When connection create database: typedb
    Given connection open read transaction for database: typedb
    Then transaction commits; fails

  Scenario Outline: <command> in a schema transaction fails
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    When transaction <command>s
    Then transaction is open: false
    Examples:
      | command |
      | close   |
      | commit  |

  Scenario Outline: <command> in a write transaction fails
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert $person isa person;
      """
    When transaction <command>s
    Then transaction is open: false
    Examples:
      | command |
      | close   |
      | commit  |

  Scenario: schema modification in a write transaction fails
    Given connection create database: typedb
    Given connection open write transaction for database: typedb
    Then typeql schema query; fails
      """
      define entity person;
      """

  Scenario: write data in a schema transaction is allowed
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Then typeql schema query
      """
      define entity person;
      """
    Then typeql write query
      """
      insert $x isa person;
      """
    Then transaction commits

    # TODO: Fix rollback
#  Scenario: commit after a schema transaction rollback does nothing
#    Given connection create database: typedb
#    Given connection open schema transaction for database: typedb
#    When typeql schema query
#      """
#      define entity person;
#      """
#    When transaction rollbacks
#    When transaction commits
#    When connection open read transaction for database: typedb
#    When typeql read query
#      """
#      match entity $x;
#      """
#    Then answer size is: 0

    # TODO: Fix rollback
#  Scenario: commit after a write transaction rollback does nothing
#    Given connection create database: typedb
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define entity person;
#      """
#    Given transaction commits
#    Given connection open write transaction for database: typedb
#    When typeql write query
#      """
#      insert $x isa person;
#      """
#    When transaction rollbacks
#    When transaction commits
#    When connection open read transaction for database: typedb
#    When typeql read query
#      """
#      match $x isa person;
#      """
#    Then answer size is: 0

  @ignore-typedb
  Scenario: transaction timeouts are configurable
    When connection create database: typedb
    Then set session option session-idle-timeout-millis to: 20000
    Given connection open schema session for database: typedb
    Given set transaction option transaction-timeout-millis to: 10000
    When session opens transaction of type: write
    Then wait 8 seconds
    Then typeql schema query
      """
      define entity person;
      """
    Then wait 4 seconds
    Then typeql schema query; fails
      """
      define entity person;
      """
