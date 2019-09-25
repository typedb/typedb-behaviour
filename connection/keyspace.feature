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

Feature: Keyspace

  Background:
    Given connection has been opened
    Given connection has no keyspaces

  Scenario: connection can create keyspace
      # This  step should be rewritten once we can create keypsaces without opening sessions
    When connection open session for keyspace: alice
    Then connection has keyspace: alice

  Scenario: connection can create multiple keyspaces
      # This  step should be rewritten once we can create keypsaces without opening sessions
    When connection open sessions for keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then connection has keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |

  Scenario: connection can delete a keyspace
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection open sessions for keyspaces:
      | alice |
    Then connection delete keyspace: alice
    Then connection does not have keyspace: alice

  Scenario: connection can delete multiple keyspaces
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection open sessions for keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then connection delete keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
    Then connection does not have keyspaces:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
