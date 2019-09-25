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

  Scenario: connection can open session for default keyspace
    When connection open session for keyspace: grakn
    Then session is null: false
    Then session is open: true
    Then session has keyspace: grakn

  Scenario: connection can open session for named keyspace
    When connection open session for keyspace: alice
    Then session is null: false
    Then session is open: true
    Then session has keyspace: alice

  Scenario: connection open multiple sessions for different keyspaces
    When connection open sessions for keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then sessions are null: false
    Then sessions are open: true
    Then sessions have correct keyspaces:
      | alice   | alice   |
      | bob     | bob     |
      | charlie | charlie |
      | dylan   | dylan   |

  Scenario: connection open multiple sessions in parallel
    When connection open sessions in parallel for different keyspaces: 32
    Then sessions in parallel are null: false
    Then sessions in parallel are open: true
    Then sessions in parallel have correct keyspaces