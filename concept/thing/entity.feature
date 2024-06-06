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
    Given entity(person) set owns: username
    Given entity(person) get owns: username, set annotation: @key
    Given entity(person) set owns: email
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
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    Then entity $a get has(username) contain: $alice
    Then entity $a get has with annotations: @key; contain: $alice
    Then attribute $alice get owners contain: $a
    When transaction commits
    When connection opens read transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    Then entity $a get has(username) contain: $alice
    Then entity $a get has with annotations: @key; contain: $alice
    Then attribute $alice get owners contain: $a

  Scenario: Entity can unset keys
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then entity $a get has(username) do not contain: $alice
    Then entity $a get has with annotations: @key; do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    Then entity $a get has(username) contain: $alice
    When entity $a unset has: $alice
    Then entity $a get has(username) do not contain: $alice
    Then entity $a get has with annotations: @key; do not contain: $alice
    Then attribute $alice get owners do not contain: $a
    Then transaction commits; fails

  Scenario: Entity that has its key unset cannot be committed
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When entity $a unset has: $alice
    Then transaction commits; fails
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(username) get instance with value: alice
    When entity $a unset has: $alice
    Then transaction commits; fails

  Scenario: Entity cannot have more than one key for a given key type
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When $bob = attribute(username) put instance with value: bob
    When entity $a set has: $alice
    Then entity $a set has: $bob; fails
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $bob = attribute(username) put instance with value: bob
    Then entity $a set has: $bob; fails

  Scenario: Entity cannot have a key that has been taken
    When $a = entity(person) create new instance
    When $alice = attribute(username) put instance with value: alice
    When entity $a set has: $alice
    When transaction commits
    When connection opens write transaction for database: typedb
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
    When connection opens read transaction for database: typedb
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
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) contain: $email
    Then entity $a get has contain: $email
    Then attribute $email get owners contain: $a
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then attribute $email get owners do not contain: $a
    When entity $a set has: $email
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When entity $a set has: $email
    When entity $a unset has: $email
    Then entity $a get has(email) do not contain: $email
    Then entity $a get has do not contain: $email
    Then attribute $email get owners do not contain: $a
    When transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    Then entity $a get has(email) do not contain: $email
    Then attribute $email get owners do not contain: $a

  Scenario: Entity cannot be given an attribute after deletion
    When $a = entity(person) create new instance with key(username): alice
    When $email = attribute(email) put instance with value: alice@email.com
    When delete entity: $a
    Then entity $a is deleted: true
    When entity $a set has: $email; fails

  # TODO: Refactor for already existing "Given"
  Scenario: Entity types can only commit keys if every instance owns a distinct key
    When put attribute type: email
    When attribute(email) set value-type: string
    When put attribute type: username
    When attribute(username) set value-type: string
    When entity(person) set owns: username
    When entity(person) get owns: username, set annotation: @key
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) create new instance with key(username): alice
    When $b = entity(person) create new instance with key(username): bob
    Then transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key; fails
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    Then transaction commits
    When connection opens write transaction for database: typedb
    When $a = entity(person) get instance with key(username): alice
    When $alice = attribute(email) as(string) put: alice@vaticle.com
    When entity $a set has: $alice
    When $b = entity(person) get instance with key(username): bob
    When $bob = attribute(email) as(string) put: bob@vaticle.com
    When entity $b set has: $bob
    Then transaction commits
    When connection opens schema transaction for database: typedb
    When entity(person) set owns: email
    When entity(person) get owns: email, set annotation: @key
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key
    Then transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: email; get annotations contain: @key
    Then entity(person) get owns: username; get annotations contain: @key
