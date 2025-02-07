# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Entity

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    # Write schema for the test scenarios
    Given create attribute type: username
    Given attribute(username) set value type: string
    Given create attribute type: email
    Given attribute(email) set value type: string
    Given create entity type: person
    Given entity(person) set owns: username
    Given entity(person) get owns(username) set annotation: @key
    Given entity(person) set owns: email
    Given transaction commits
    Given connection open write transaction for database: typedb

  Scenario: Entity can be created
    When $a = entity(person) create new instance with key(username): alice
    Then entity $a exists
    Then entity $a has type: person
    Then entity(person) get instances contain: $a
    Then transaction commits
    When connection open read transaction for database: typedb
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
    When connection open write transaction for database: typedb
    Then entity(person) get instances is empty
    When $a = entity(person) create new instance with key(username): alice
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity(person) get instances is empty
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(person) get instances is empty

  Scenario: Entity can have keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    Then entity $a get has(username) contain: $alice
    Then entity $a get key has; contain: $alice
    Then attribute $alice get owners contain: $a
    When transaction commits
    When connection open read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    Then entity $a get has(username) contain: $alice
    Then entity $a get key has; contain: $alice
    Then attribute $alice get owners contain: $a

  Scenario: Entity can unset keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then entity $a get has(username) do not contain: $alice
    Then entity $a get key has; do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    When entity $a set has: $alice
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    Then entity $a get has(username) contain: $alice
    When entity $a unset has: $alice
    Then entity $a get has(username) do not contain: $alice
    Then entity $a get key has; do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    Then transaction commits; fails

  Scenario: Entity that has its key unset cannot be committed
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then transaction commits; fails
    When connection open write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    When entity $a unset has: $alice
    Then transaction commits; fails

  Scenario: Entity cannot have more than one key for a given key type
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When $bob = attribute(username) put instance with value: bob
    When entity $a set has: $alice
    When entity $a set has: $bob
    Then transaction commits; fails
    When connection open write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $bob = attribute(username) put instance with value: bob
    When entity $a set has: $bob
    Then transaction commits; fails

  Scenario: Entity cannot have a key that has been taken
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection open write transaction for database: typedb
    When $b = entity(person) create new instance
    When $alice = attribute(username) get instance with value: alice
    Then entity $b set has: $alice; fails

  Scenario: Entity can have attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When transaction commits
    When connection open read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a

  Scenario: Entity can unset attribute
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then attribute $email does not exist
    When $email = attribute(email) put instance with value: alice@email.com
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then attribute $email exists
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then attribute $email does not exist
    When $email = attribute(email) put instance with value: alice@email.com
    Then entity $a get has(email) do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then attribute $email get owners do not contain: $a

  Scenario: Entity cannot have multiple layers of put attributes
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When entity $a set has: $email
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email

  Scenario: Entity cannot be given an attribute after deletion
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When delete entity: $a
    Then entity $a is deleted: true
    Then entity $a set has: $email; fails

  Scenario: Entity cannot be given an attribute after attribute deletion
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When delete attribute: $email
    Then attribute $email is deleted: true
    Then entity $a set has: $email; fails
    When transaction closes
    When connection open write transaction for database: typedb
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    Then entity $a get has contain: $email
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) get instance with value: alice@email.com
    Then entity $a get has contain: $email
    When delete attribute: $email
    Then attribute $email is deleted: true
    Then entity $a set has: $email; fails
    When transaction commits
    When connection open write transaction for database: typedb
    Then entity $a set has: $email; fails
    When $email = attribute(email) get instance with value: alice@email.com
    Then attribute $email does not exist
    When $a = entity(person) get instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    When delete attribute: $email
    Then attribute $email is deleted: true
    Then entity $a set has: $email; fails

  Scenario: Entity cannot be given an attribute after attribute cleanup
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection open write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then entity $a set has: $email; fails

  Scenario: Cannot create instances of abstract entity type
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create entity type: character
    When entity(character) set annotation: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then entity(character) create new instance; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When entity(character) unset annotation: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then entity(character) create new instance
    When transaction commits
    When connection open read transaction for database: typedb
    Then entity(character) get instances is not empty
