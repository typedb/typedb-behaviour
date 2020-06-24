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
    Given put attribute type: username, with value type: string
    Given put attribute type: license, with value type: string
    Given put attribute type: date, with value type: datetime
    Given put relation type: marriage
    Given relation(marriage) set relates role: wife
    Given relation(marriage) set relates role: husband
    Given relation(marriage) set key attribute type: license
    Given relation(marriage) set has attribute type: date
    Given put entity type: person
    Given entity(person) set key attribute type: username
    Given entity(person) set plays role: marriage:wife
    Given entity(person) set plays role: marriage:husband
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Relation with role player can be created
    When $m = relation(marriage) create new instance
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When $b = entity(person) create new instance
    When $bob = attribute(username) as(string) put: bob
    When entity $b set has: $bob
    When relation $m set player for role(wife): $a
    When relation $m set player for role(husband): $b
    Then relation(marriage) get instances contain: $m
    Then relation $m is null: false
    Then relation $m has type: marriage
    Then relation $m get player for role(wife): $a
    Then relation $m get player for role(husband): $b
    Then transaction commits
    When session opens transaction of type: read
    When $m = relation(marriage) get first instance
    Then relation(marriage) get instances contain: $m
    When $alice = attribute(username) as(string) get: alice
    When $a = entity(person) get instance with key: $alice
    When $bob = attribute(username) as(string) get: bob
    When $b = entity(person) get instance with key: $bob
    Then relation $m get player for role(wife): $a
    Then relation $m get player for role(husband): $b

  Scenario: Relation without role player cannot be created

  Scenario: Relation can get role players

  Scenario: Role players can get relations

  Scenario: Role player can be deleted from relation

  Scenario: Relation with role player can be deleted
