# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Attribute

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection opens schema transaction for database: typedb
    # Write schema for the test scenarios
    Given put attribute type: is-alive
    Given attribute(is-alive) set value-type: boolean
    Given attribute(is-alive) set annotation: @independent
    Given put attribute type: age
    Given attribute(age) set value-type: long
    Given attribute(age) set annotation: @independent
    Given put attribute type: score
    Given attribute(score) set value-type: double
    Given attribute(score) set annotation: @independent
    Given put attribute type: birth-date
    Given attribute(birth-date) set value-type: datetime
    Given attribute(birth-date) set annotation: @independent
    Given put attribute type: name
    Given attribute(name) set value-type: string
    Given attribute(name) set annotation: @independent
    Given put attribute type: email
    Given attribute(email) set value-type: string
    Given attribute(email) set annotation: @independent
    Given attribute(email) set annotation: @regex("\S+@\S+\.\S+")
    Given transaction commits
    Given connection opens write transaction for database: typedb
    Given set time zone: Europe/London

  Scenario: Attribute with value type boolean can be created
    When $x = attribute(is-alive) put instance with value: true
    Then attribute $x exists
    Then attribute $x has type: is-alive
    Then attribute $x has value type: boolean
    Then attribute $x has value: true
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(is-alive) get instance with value: true
    Then attribute $x exists
    Then attribute $x has type: is-alive
    Then attribute $x has value type: boolean
    Then attribute $x has value: true

  Scenario: Attribute with value type long can be created
    When $x = attribute(age) put instance with value: 21
    Then attribute $x exists
    Then attribute $x has type: age
    Then attribute $x has value type: long
    Then attribute $x has value: 21
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(age) get instance with value: 21
    Then attribute $x exists
    Then attribute $x has type: age
    Then attribute $x has value type: long
    Then attribute $x has value: 21

  Scenario: Attribute with value type double can be created
    When $x = attribute(score) put instance with value: 123.456
    Then attribute $x exists
    Then attribute $x has type: score
    Then attribute $x has value type: double
    Then attribute $x has value: 123.456
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(score) get instance with value: 123.456
    Then attribute $x exists
    Then attribute $x has type: score
    Then attribute $x has value type: double
    Then attribute $x has value: 123.456

  Scenario: Attribute with value type string can be created
    When $x = attribute(name) put instance with value: alice
    Then attribute $x exists
    Then attribute $x has type: name
    Then attribute $x has value type: string
    Then attribute $x has value: alice
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(name) get instance with value: alice
    Then attribute $x exists
    Then attribute $x has type: name
    Then attribute $x has value type: string
    Then attribute $x has value: alice

  Scenario: Attribute with value type string that satisfies the regular expression can be created
    When $x = attribute(email) put instance with value: alice@email.com
    Then attribute $x exists
    Then attribute $x has type: email
    Then attribute $x has value type: string
    Then attribute $x has value: alice@email.com
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(email) get instance with value: alice@email.com
    Then attribute $x exists
    Then attribute $x has type: email
    Then attribute $x has value type: string
    Then attribute $x has value: alice@email.com

  Scenario: Attribute with value type string that does not satisfy the regular expression cannot be created
    When attribute(email) put instance with value: alice-email-com; fails

  Scenario: Attribute with value type datetime can be created
    When $x = attribute(birth-date) put instance with value: 1990-01-01 11:22:33
    Then attribute $x exists
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has value: 1990-01-01 11:22:33
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute $x exists
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has value: 1990-01-01 11:22:33

  Scenario: Attribute with value type boolean can be retrieved by its value
    When $x = attribute(is-alive) put instance with value: true
    Then attribute(is-alive) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(is-alive) get instance with value: true
    Then attribute(is-alive) get instances contain: $x

  Scenario: Attribute with value type long can be retrieved by its value
    When $x = attribute(age) put instance with value: 21
    Then attribute(age) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(age) get instance with value: 21
    Then attribute(age) get instances contain: $x

  Scenario: Attribute with value type double can be retrieved by its value
    When $x = attribute(score) put instance with value: 123.456
    Then attribute(score) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(score) get instance with value: 123.456
    Then attribute(score) get instances contain: $x

  Scenario: Attribute with value type string can be retrieved by its value
    When $x = attribute(name) put instance with value: alice
    Then attribute(name) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(name) get instance with value: alice
    Then attribute(name) get instances contain: $x

  Scenario: Attribute with value type datetime can be retrieved by its value
    When $x = attribute(birth-date) put instance with value: 1990-01-01 11:22:33
    Then attribute(birth-date) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute(birth-date) get instances contain: $x

  Scenario: Datetime attribute can be inserted in one timezone and retrieved in another with no change in the value
    When set time zone: Asia/Calcutta
    When $x = attribute(birth-date) put instance with value: 2001-08-23 08:30:00
    Then attribute $x exists
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has value: 2001-08-23 08:30:00
    When transaction commits
    When connection opens read transaction for database: typedb
    When set time zone: America/Chicago
    When $x = attribute(birth-date) get instance with value: 2001-08-23 08:30:00
    Then attribute $x exists
    Then attribute $x has type: birth-date
    Then attribute $x has value type: datetime
    Then attribute $x has value: 2001-08-23 08:30:00

  Scenario: Attribute with value type boolean can be deleted
    When $x = attribute(is-alive) put instance with value: true
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(is-alive) get instance with value: true
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(is-alive) get instance with value: true
    Then attribute $x does not exist
    When $x = attribute(is-alive) put instance with value: true
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(is-alive) get instance with value: true
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(is-alive) get instance with value: true
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(is-alive) get instance with value: true
    Then attribute $x does not exist

  Scenario: Attribute with value type long can be deleted
    When $x = attribute(age) put instance with value: 21
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(age) get instance with value: 21
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(age) get instance with value: 21
    Then attribute $x does not exist
    When $x = attribute(age) put instance with value: 21
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(age) get instance with value: 21
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(age) get instance with value: 21
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(age) get instance with value: 21
    Then attribute $x does not exist

  Scenario: Attribute with value type double can be deleted
    When $x = attribute(score) put instance with value: 123.456
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(score) get instance with value: 123.456
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(score) get instance with value: 123.456
    Then attribute $x does not exist
    When $x = attribute(score) put instance with value: 123.456
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(score) get instance with value: 123.456
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(score) get instance with value: 123.456
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(score) get instance with value: 123.456
    Then attribute $x does not exist

  Scenario: Attribute with value type string can be deleted
    When $x = attribute(name) put instance with value: alice
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(name) get instance with value: alice
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(name) get instance with value: alice
    Then attribute $x does not exist
    When $x = attribute(name) put instance with value: alice
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(name) get instance with value: alice
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(name) get instance with value: alice
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(name) get instance with value: alice
    Then attribute $x does not exist

  Scenario: Attribute with value type datetime can be deleted
    When $x = attribute(birth-date) put instance with value: 1990-01-01 11:22:33
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute $x does not exist
    When $x = attribute(birth-date) put instance with value: 1990-01-01 11:22:33
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(birth-date) get instance with value: 1990-01-01 11:22:33
    Then attribute $x does not exist

  Scenario: Attribute with value type boolean can be owned

  Scenario: Attribute with value type long can be owned

  Scenario: Attribute with value type double can be owned

  Scenario: Attribute with value type string can be owned

  Scenario: Attribute with value type datetime can be owned
