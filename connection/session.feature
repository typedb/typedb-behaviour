# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Connection Session

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database

  Scenario: for one database, open one session
    When connection create database: typedb
    When connection open session for database: typedb
    Then session is null: false
    Then session is open: true
    Then session has database: typedb

  Scenario: for one database, open many sessions
    When connection create database: typedb
    When connection open sessions for databases:
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have databases:
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |

  Scenario: for one database, open many sessions in parallel
    When connection create database: typedb
    When connection open sessions in parallel for databases:
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have databases:
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |
      | typedb |

  Scenario: for many databases, open many sessions
    When connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When connection open sessions for databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then sessions are null: false
    Then sessions are open: true
    Then sessions have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |


  Scenario: for many databases, open many sessions in parallel
    When connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When connection open sessions in parallel for databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |


  Scenario: write schema in a data session throws
    When connection create database: typedb
    Given connection open data session for database: typedb
    When session opens transaction of type: write
    Then typeql define; throws exception containing "session type does not allow"
      """
      define person sub entity;
      """


  Scenario: write data in a schema session throws
    When connection create database: typedb
    Given connection open schema session for database: typedb
    When session opens transaction of type: write
    Then typeql define
      """
      define person sub entity;
      """
    Then typeql insert; throws exception containing "session type does not allow"
      """
      insert $x isa person;
      """
