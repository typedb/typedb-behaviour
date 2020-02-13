#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2019 Grakn Labs Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

Feature: Connection Transaction

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace

  Scenario: for one keyspace and one session, open one transaction to read
    Given connection open session for keyspace:
      | grakn   |
    When for each session, open transaction of type:
      | read    |
    Then for each session, transaction is null: false
    Then for each session, transaction is open: true
    Then for each session, transaction has type: read
    Then for all sessions, transaction has keyspace:
      | grakn   |

  Scenario: for one keyspace and one session, open one transaction to write
    Given connection open session for one keyspace:
      | grakn   |
    When for each session, open transaction of type:
      | write   |
    Then for each session, transaction is null: false
    Then for each session, transaction is open: true
    Then for each session, transaction has type:
      | write   |
    Then for all sessions, transaction has keyspace:
      | grakn   |

  Scenario: for one keyspace and one session, open many transactions to read
    Given connection open session for one keyspace:
      | grakn   |
    When for each session, open transactions of type:
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
    Then for each session, transactions are null: false
    Then for each session, transactions are open: true
    Then for each session, transactions have type:
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
      | read    |
    Then for all sessions, transactions have keyspace:
      | grakn   |

  Scenario: for one keyspace and one session, open many transactions to write
    Given connection open session for one keyspace:
      | grakn   |
    When for each session, open transactions of type:
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
    Then for each session, transactions are null: false
    Then for each session, transactions are open: true
    Then for each session, transactions have type:
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
      | write   |
    Then for all sessions, transactions have keyspace:
      | grakn   |

  Scenario: for one keyspace and one session, open many transactions to read and write
    Given connection open 1 session for one keyspace: grakn
    When session open many transactions of type:
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
    Then for each session, transactions are null: false
    Then for each session, transactions are open: true
    Then for each session, transactions have type:
    Then for all sessions, transactions have keyspace:
      | grakn   |

#  Scenario: for one keyspace and one session, open many transactions in parallel of type read
#    Given connection open 1 session for one keyspace: grakn
#    When session open 32 transactions in parallel of type: read
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: read
#    Then transactions in parallel have keyspace: grakn
#
#  Scenario: for one keyspace and one session, open many transactions in parallel of type write
#    Given connection open 1 session for one keyspace: grakn
#    When session open 32 transactions in parallel of type: write
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: write
#    Then transactions in parallel have keyspace: grakn
#
#  Scenario: for one keyspace and one session, open many transactions in parallel to read and write
#
#  Scenario: for one keyspace and many sessions, each session opens one transaction to read
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 1 transaction of type: read
#    Then transaction is null: false
#    Then transaction is open: true
#    Then transaction has type: read
#    Then transaction has keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens one transaction to write
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 1 transaction of type: write
#    Then transaction is null: false
#    Then transaction is open: true
#    Then transaction has type: write
#    Then transaction has keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions to read
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 32 transaction of type: read
#    Then transactions are null: false
#    Then transactions are open: true
#    Then transactions have type: read
#    Then transactions have keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions to write
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 32 transaction of type: write
#    Then transactions are null: false
#    Then transactions are open: true
#    Then transactions have type: write
#    Then transactions have keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions to read and write
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions in parallel to read
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 32 transaction in parallel of type: read
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: read
#    Then transactions in parallel have keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions in parallel to write
#    Given connection open 32 sessions for one keyspace: grakn
#    When sessions each open 32 transaction in parallel of type: write
#    Then transactions in parallel are null: false
#    Then transactions in parallel are open: true
#    Then transactions in parallel have type: write
#    Then transactions in parallel have keyspace: grakn
#
#  Scenario: for one keyspace and many sessions, each session opens many transactions in parallel to read and write






#  Scenario: one keyspace, many sessions in parallel, one transactions to read
#
#  Scenario: one keyspace, many sessions in parallel, one transactions to write
#
#  Scenario: one keyspace, many sessions in parallel, many transactions to read
#
#  Scenario: one keyspace, many sessions in parallel, many transactions to write
#
#  Scenario: one keyspace, many sessions in parallel, many transactions in parallel to read
#
#  Scenario: one keyspace, many sessions in parallel, many transactions in parallel to write