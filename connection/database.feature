# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Connection Database

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases

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

    Then connection has databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

  Scenario: create many databases in parallel
    When connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then connection has databases:
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
    Then connection has 0 databases

  Scenario: connection can delete many databases
      Given connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When connection delete databases:
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

    Then connection has 0 databases

  Scenario: delete many databases in parallel
      Given connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When connection delete databases in parallel:
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

    Then connection has 0 databases

  Scenario: create delete and recreate a database
    When connection create database: alice
    Then connection has database: alice
    When connection delete database: alice
    Then connection does not have database: alice
    When connection create database: alice
    Then connection has database: alice

  Scenario: delete a nonexistent database fails
    When connection delete database: typedb; fails

  Scenario: database cannot be deleted if it has open transactions
    When connection create database: typedb
    Then connection has database: typedb
    When connection open schema transaction for database: typedb
    Then transaction is open: true
    Then connection delete database: typedb; fails
    Then typeql schema query
      """
      define entity person;
      """
    Then transaction commits
    Then connection delete database: typedb
    Then connection does not have database: typedb

