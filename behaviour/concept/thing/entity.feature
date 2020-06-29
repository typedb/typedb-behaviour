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
    Given put attribute type: username, with value type: string
    Given put attribute type: email, with value type: string
    Given put entity type: person
    Given entity(person) set key attribute type: username
    Given entity(person) set has attribute type: email
    Given transaction commits
    Given connection close all sessions
    Given connection open data session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Entity can be created
    When $a = entity(person) create new instance with key(username): alice
    Then entity $a is null: false
    Then entity $a has type: person
    Then entity(person) get instances contain: $a
    Then transaction commits
    When session opens transaction of type: read
    When $a = entity(person) get instance with key(username): alice
    Then entity(person) get instances contain: $a

  Scenario: Entity cannot be created when it misses a key
    When $a = entity(person) create new instance
    Then entity $a is null: false
    Then entity $a has type: person
    Then entity(person) get instances contain: $a
    Then transaction commits successfully: false

  Scenario: Entity can be deleted
    When $a = entity(person) create new instance with key(username): alice
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity(person) get instances is empty
    When transaction commits
    When session opens transaction of type: write
    Then entity(person) get instances is empty
    When $a = entity(person) create new instance with key(username): alice
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity(person) get instances is empty
    When transaction commits
    When session opens transaction of type: read
    Then entity(person) get instances is empty

  Scenario: Entity can have keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    Then entity $a get keys(username) contain: $alice
    Then entity $a get keys contain: $alice
    Then attribute $alice get owners contain: $a
    When transaction commits
    When session opens transaction of type: read
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) as(string) get: alice
    Then entity $a get keys(username) contain: $alice
    Then entity $a get keys contain: $alice
    Then attribute $alice get owners contain: $a

  Scenario: Entity can remove keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When entity $a remove has: $alice
    Then entity $a get keys(username) do not contain: $alice
    Then entity $a get keys do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    When entity $a set has: $alice
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) as(string) get: alice
    Then entity $a get keys(username) contain: $alice
    When entity $a remove has: $alice
    Then entity $a get keys(username) do not contain: $alice
    Then entity $a get keys do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    When transaction commits successfully: false

  Scenario: Entity can have attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) as(string) put: alice@email.com
    When entity $a set has: $email
    Then entity $a get attributes(email) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a
    When transaction commits
    When session opens transaction of type: read
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a

  Scenario: Entity can remove attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) as(string) put: alice@email.com
    When entity $a set has: $email
    When entity $a remove has: $email
    Then entity $a get attributes(email) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a
    When entity $a remove has: $email
    Then entity $a get attributes(email) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    When entity $a set has: $email
    When entity $a remove has: $email
    Then entity $a get attributes(email) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When session opens transaction of type: write
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) do not contain: $email
    Then attribute $email get owners do not contain: $a

  Scenario: Entity can play a role in a relation

  Scenario: Entity can retrieve relations where it plays a role in

  Scenario: Entity can retrieve role types it plays

