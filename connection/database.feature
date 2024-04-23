# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Connection Database

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database

  Scenario: create one database
    When connection create database: alice
    Then connection has database: alice

  Scenario: create many databases
    When connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection has databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

  Scenario: create many databases in parallel
    When  connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection has databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

  Scenario: delete one database
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create database: alice
    When connection delete database: alice
    Then connection does not have database: alice
    Then connection does not have any database

  Scenario: connection can delete many databases
      Given connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When  connection delete databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection does not have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then connection does not have any database

  Scenario: delete many databases in parallel
      Given connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When  connection delete databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then connection does not have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then connection does not have any database

  Scenario: create delete and recreate a database
    When connection create database: alice
    Then connection has database: alice
    When connection delete database: alice
    Then connection does not have database: alice
    When connection create database: alice
    Then connection has database: alice

  Scenario: delete a nonexistent database throws an error
    When connection delete database; throws exception: typedb

  # TODO: Verify the TODO is still relevant
  # # TODO: currently throws in @After; re-enable when we are able to check if sessions are alive (see driver-java#225)
  @ignore
  Scenario: delete a database causes open transactions to fail
    When connection create database: typedb
    When connection opens write transaction for database: typedb
    When connection delete database: typedb
    Then connection does not have database: typedb
    Then typeql define; throws exception containing "transaction has been closed"
      """
      define person sub entity;
      """

