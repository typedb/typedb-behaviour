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

Feature: Concept Thing Type

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Thing type root can retrieve all the subtypes
    When put entity type: person
    When put attribute type: is-alive, value type: boolean
    When put attribute type: age, value type: long
    When put attribute type: rating, value type: double
    When put attribute type: name, value type: string
    When put attribute type: birth-date, value type: datetime
    When put relation type: marriage
    When relation(marriage) set relates role: husband
    When relation(marriage) set relates role: wife
    Then thing type root get supertypes contain:
      | thing |
    Then thing type root get supertypes do not contain:
      | person     |
      | is-alive   |
      | age        |
      | rating     |
      | name       |
      | birth-date |
      | marriage   |
      | husband    |
      | wife       |
    Then thing type root get subtypes contain:
      | thing      |
      | person     |
      | is-alive   |
      | age        |
      | rating     |
      | name       |
      | birth-date |
      | marriage   |
    Then thing type root get subtypes do not contain:
      | husband |
      | wife    |
