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
    Given connection delete all keyspaces
    Given connection does not have any keyspace

  Scenario: connection open one session for one keyspace
    When connection open 1 session for one keyspace: alice
    Then session is null: false
    Then session is open: true
    Then session has keyspace: alice

  Scenario: connection open many sessions for one keyspace
    When connection open 32 sessions for one keyspace: alice
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have keyspace: alice

  Scenario: connection open many sessions for many keyspaces
    When connection open many sessions for many keyspaces:
      | 1 | alice   |
      | 2 | bob     |
      | 3 | charlie |
      | 4 | dylan   |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have keyspaces:
      | 1 | alice   |
      | 2 | bob     |
      | 3 | charlie |
      | 4 | dylan   |

  Scenario: connection open many sessions in parallel for one keyspace
    When connection open 32 sessions in parallel for one keyspace: alice
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have keyspace: alice

#  Scenario: connection open many sessions in parallel for many keyspaces
#    When connection open many sessions for many keyspaces:
#      | alice   |
#      | bob     |
#      | charlie |
#      | dylan   |
#      | eve     |
#      | frank   |
#      | george  |
#      | heidi   |
#      | ivan    |
#      | judy    |
#      | mike    |
#      | neil    |
#    Then sessions are null: false
#    Then sessions are open: true
#    Then sessions have correct keyspaces:
#      | alice   |
#      | bob     |
#      | charlie |
#      | dylan   |
#      | eve     |
#      | frank   |
#      | george  |
#      | heidi   |
#      | ivan    |
#      | judy    |
#      | mike    |
#      | neil    |
#
#  Scenario: connection open many sessions in parallel for many random keyspaces
#    When connection open 32 sessions in parallel for many keyspaces: random
#    Then sessions in parallel are null: false
#    Then sessions in parallel are open: true
#    Then sessions in parallel have correct keyspaces