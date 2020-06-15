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

Feature: Concept Relation

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open schema session for keyspace: grakn
    Given session opens transaction of type: write
    # Write schema for the test scenarios
    Given put attribute type: email, with value type: string
    Given put attribute type: license, with value type: string
    Given put attribute type: date, with value type: datetime
    Given put relation type: marriage
    Given relation(marriage) set relates role: husband
    Given relation(marriage) set relates role: wife
    Given relation(marriage) set key attribute type: license
    Given relation(marriage) set has attribute type: date
    Given put entity type: person
    Given entity(person) set key attribute type: email
    Given entity(person) set plays role: marriage:husband
    Given entity(person) set plays role: marriage:wife
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Relation can be created
    When $x = relation(marriage) create new instance
    Then relation $x is null: false
    Then relation $x has type: marriage
    Then relation(marriage) get instances contain: $x
    Then transaction commits
    When session opens transaction of type: read
    When $x = relation(marriage) get first instance
    Then relation(marriage) get instances contain: $x