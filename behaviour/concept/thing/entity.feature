#
# Copyright (C) 2020 Grakn Labs
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

Feature: Concept Entity

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write
    # Write schema for the test scenarios
    Given put attribute type: email, with value type: string
    Given put attribute type: name, with value type: string
    Given put entity type: person
    Given entity(person) set key attribute: email
    Given entity(person) set has attribute: name
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Entity can be created
    When $x = entity(person) create new instance
    Then entity $x is null: false
    Then entity $x has type: person
    Then transaction commits

  Scenario: Entity can be retrieved from its type

  Scenario: Entity can be deleted

  Scenario: Entity can have key

  Scenario: Entity can get keys

  Scenario: Entity can remove key

  Scenario: Entity can have attribute

  Scenario: Entity can get attributes

  Scenario: Entity can remove attribute

