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
    Given entity(person) set key attribute type: email
    Given entity(person) set has attribute type: name
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
    When $x = entity(person) create new instance
    Then entity(person) get instances contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = entity(person) get first instance
    Then entity(person) get instances contain: $x
    # TODO: lookup by key

  Scenario: Entity can be deleted
    When $x = entity(person) create new instance
    When delete entity: $x
    Then entity(person) get instances is empty
    When transaction commits
    When session opens transaction of type: write
    Then entity(person) get instances is empty
    When $x = entity(person) create new instance
    When transaction commits
    When session opens transaction of type: write
    When $x = entity(person) get first instance
    When delete entity: $x
    Then entity(person) get instances is empty
    When transaction commits
    When session opens transaction of type: read
    Then entity(person) get instances is empty

  Scenario: Entity can have keys
    When $x = entity(person) create new instance
    When $y = attribute(email) as(string) put: name@email.com
    When entity $x set has: $y
    Then entity $x get keys(email) contain: $y
    Then entity $x get keys contain: $y
    Then attribute $y get owners contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = entity(person) get first instance
    When $y = attribute(email) as(string) get: name@email.com
    Then entity $x get keys(email) contain: $y
    Then entity $x get keys contain: $y
    Then attribute $y get owners contain: $x

  Scenario: Entity can remove keys
    When $x = entity(person) create new instance
    When $y = attribute(email) as(string) put: name@email.com
    When entity $x set has: $y
    When entity $x remove key: $y
    Then entity $x get keys(email) do not contain: $y
    Then entity $x get keys do not contain: $y
    Then attribute $y get owners do not contain: $x
    When transaction commits
    When session opens transaction of type: write
    When $x = entity(person) get first instance
    When $y = attribute(email) as(string) get: name@email.com
    Then entity $x get keys(email) do not contain: $y
    Then entity $x get keys do not contain: $y
    Then attribute $y get owners do not contain: $x
    When entity $x set has: $y
    When transaction commits
    When session opens transaction of type: write
    When $x = entity(person) get first instance
    When $y = attribute(email) as(string) get: name@email.com
    Then entity $x get keys(email) contain: $y
    When entity $x remove key: $y
    Then entity $x get keys(email) do not contain: $y
    Then entity $x get keys do not contain: $y
    Then attribute $y get owners do not contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = entity(person) get first instance
    When $y = attribute(email) as(string) get: name@email.com
    Then entity $x get keys(email) do not contain: $y
    Then attribute $y get owners do not contain: $x

  Scenario: Entity can have attribute
    When $x = entity(person) create new instance
    When $y = attribute(name) as(string) put: alice
    When entity $x set has: $y
    Then entity $x get attributes(name) contain: $y
    Then entity $x get attributes contain: $y
    Then attribute $y get owners contain: $x
    When transaction commits
    When session opens transaction of type: read
    When $x = entity(person) get first instance
    When $y = attribute(name) as(string) get: alice
    Then entity $x get attributes(name) contain: $y
    Then entity $x get attributes contain: $y
    Then attribute $y get owners contain: $x

  Scenario: Entity can get attributes

  Scenario: Entity can remove attribute

