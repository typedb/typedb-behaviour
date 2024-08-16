# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Ordered Ownership

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    # Write schema for the test scenarios
    Given create attribute type: username
    Given attribute(username) set value type: string
    Given create attribute type: name
    Given attribute(name) set value type: string
    Given attribute(name) set annotation: @independent
    Given create attribute type: birth-date
    Given attribute(birth-date) set value type: date
    Given create attribute type: email
    Given attribute(email) set value type: string
    Given create entity type: person
    Given entity(person) set owns: username
    Given entity(person) get owns(username) set annotation: @key
    Given entity(person) set owns: name
    Given entity(person) set owns: birth-date
    Given entity(person) set owns: email
    Given entity(person) get owns(email) set ordering: ordered
    Given transaction commits
    Given connection open write transaction for database: typedb

  Scenario: Entity can have an ordered collection of attributes
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits

  Scenario: Ordered attributes can be retrieved and indexed
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt

  Scenario: Ordered attributes can be retrieved as unordered
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) contain: $alt

  Scenario: Ordered attributes can contain the same attribute multiple times
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt, $main, $main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt
    Then attribute $emails[2] is $main
    Then attribute $emails[3] is $main
    Then attribute $emails[4] is $alt

  Scenario: Ordered attributes can be overwritten
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open write transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt
    When $alt2 = attribute(email) put instance with value: alice@email.net
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) contain: $alt
    Then entity $a get has(email) do not contain: $alt2
    When entity $a set has(email[]): [$alt2, $main]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $alt2
    Then attribute $emails[1] is $main
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) do not contain: $alt
    Then entity $a get has(email) contain: $alt2

  Scenario: Non-independent attributes are cleaned up without owners
    When $p = entity(person) create new instance with key(username): "k"
    When $b = attribute(birth-date) put instance with value: 2024-01-15
    When entity $p set has: $b
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(username) get instances is not empty
    When $p = entity(person) get instance with key(username): "k"
    When $b = attribute(birth-date) get instance with value: 2024-01-15
    When entity $p unset has: $b
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(birth-date) get instances is empty

  Scenario: Independent attributes are not cleaned up without owners
    When $p = entity(person) create new instance with key(username): "k"
    When $n = attribute(name) put instance with value: "k"
    When entity $p set has: $n
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(name) get instances is not empty
    When $p = entity(person) get instance with key(username): "k"
    When $n = attribute(name) get instance with value: "k"
    When entity $p unset has: $n
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get instances is not empty
