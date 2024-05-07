# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Entity

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection opens schema transaction for database: typedb
    # Write schema for the test scenarios
    Given put attribute type: username
    Given attribute(username) set value-type: string
    Given put attribute type: email
    Given attribute(email) set value-type: string
    Given put entity type: person
    Given entity(person) set owns attribute type: username, with annotations: key
    Given entity(person) set owns attribute type: email
    Given transaction commits
    Given connection opens write transaction for database: typedb

  Scenario: Entity can be created
    When $a = entity(person) create new instance with key(username): alice
    Then entity $a exists
    Then entity $a has type: person
    Then entity(person) get instances contain: $a
    Then transaction commits
    When connection opens read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity(person) get instances contain: $a

  Scenario: Entity cannot be created when it misses a key
    When $a = entity(person) create new instance
    Then entity $a exists
    Then entity $a has type: person
    Then entity(person) get instances contain: $a
    Then transaction commits; fails

  Scenario: Entity can be deleted
    When $a = entity(person) create new instance with key(username): alice
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity(person) get instances is empty
    When transaction commits
    When connection opens write transaction for database: typedb
    Then entity(person) get instances is empty
    When $a = entity(person) create new instance with key(username): alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity(person) get instances is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get instances is empty

  Scenario: Entity can have keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    Then entity $a get attributes(username) as(string) contain: $alice
    Then entity $a get keys contain: $alice
    Then attribute $alice get owners contain: $a
    When transaction commits
    When connection opens read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) as(string) get: alice
    Then entity $a get attributes(username) as(string) contain: $alice
    Then entity $a get keys contain: $alice
    Then attribute $alice get owners contain: $a

  Scenario: Entity can unset keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then entity $a get attributes(username) as(string) do not contain: $alice
    Then entity $a get keys do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) as(string) get: alice
    Then entity $a get attributes(username) as(string) contain: $alice
    When entity $a unset has: $alice
    Then entity $a get attributes(username) as(string) do not contain: $alice
    Then entity $a get keys do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    Then transaction commits; fails

  Scenario: Entity that has its key unset cannot be committed
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then transaction commits; fails
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) as(string) get: alice
    When entity $a unset has: $alice
    Then transaction commits; fails

  Scenario: Entity cannot have more than one key for a given key type
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When $bob = attribute(username) as(string) put: bob
    When entity $a set has: $alice
    Then entity $a set has: $bob; fails
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When $bob = attribute(username) as(string) put: bob
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $bob = attribute(username) as(string) get: bob
    Then entity $a set has: $bob; fails

  Scenario: Entity cannot have a key that has been taken
    When $a = entity(person) create new instance
    When $alice = attribute(username) as(string) put: alice
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $b = entity(person) create new instance
    When $alice = attribute(username) as(string) get: alice
    Then entity $b set has: $alice; fails

  Scenario: Entity can have attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) as(string) put: alice@email.com
    When entity $a set has: $email
    Then entity $a get attributes(email) as(string) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a
    When transaction commits
    When connection opens read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) as(string) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a

  Scenario: Entity can unset attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) as(string) put: alice@email.com
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) as(string) contain: $email
    Then entity $a get attributes contain: $email
    Then attribute $email get owners contain: $a
    When entity $a unset has: $email
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then entity $a get attributes do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) as(string) get: alice@email.com
    Then entity $a get attributes(email) as(string) do not contain: $email
    Then attribute $email get owners do not contain: $a

  Scenario: Entity cannot be given an attribute after deletion
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) as(string) put: alice@email.com
    When delete entity: $a
    Then entity $a is deleted: true
    When entity $a set has: $email; fails

  Scenario: Entity can play a role in a relation

  Scenario: Entity can retrieve relations where it plays a role in

  Scenario: Entity can retrieve role types it plays

