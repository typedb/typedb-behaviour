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

Feature: Connection Keyspace

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace

  Scenario: connection can create one keyspace
    When  connection create one keyspace: alice
    Then  connection has one keyspace: alice

  Scenario: connection can create multiple keyspaces
    When  connection create multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then  connection has multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |

  Scenario: connection can delete one keyspace
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create one keyspace: alice
    When  connection delete one keyspace: alice
    Then  connection does not have one keyspace: alice
    Then  connection does not have any keyspace

  Scenario: connection can delete multiple keyspaces
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    When  connection delete multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then  connection does not have multiple keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then  connection does not have any keyspace