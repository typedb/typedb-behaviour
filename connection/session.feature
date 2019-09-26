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

Feature: Session

  Background:
    Given connection has been opened
    Given connection has no keyspaces

  Scenario: connection can open session
    When connection open 1 session for one keyspace: alice
    Then session is null: false
    Then session is open: true
    Then session has keyspace: alice

  Scenario: connection open multiple sessions for one keyspace
    When connection open 32 sessions for one keyspace: alice
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have correct keyspace: alice

  Scenario: connection open multiple sessions for multiple keyspaces
    When connection open multiple sessions for multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have correct keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |

  Scenario: connection open multiple sessions in parallel for one keyspace
    When connection open 32 sessions for one keyspace: alice
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have correct keyspace: alice

  Scenario: connection open multiple sessions in parallel for multiple keyspaces
    When connection open multiple sessions for multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have correct keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |
      | george  |
      | heidi   |
      | ivan    |
      | judy    |
      | mike    |
      | neil    |

  Scenario: connection open multiple sessions in parallel for multiple random keyspaces
    When connection open 32 sessions in parallel for multiple keyspaces: random
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have correct keyspaces