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
    Given put attribute type: event-date
    Given attribute(event-date) set value-type: datetimetz
    Given attribute(event-date) set annotation: @independent
    Given put attribute type: schedule-interval
    Given attribute(schedule-interval) set value-type: duration
    Given attribute(schedule-interval) set annotation: @independent
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

  Scenario Outline: Attribute with value type <type> can be created
    When $x = attribute(<attr>) put instance with value: <value>
    Then attribute $x exists
    Then attribute $x has type: <attr>
    Then attribute $x has value type: <type>
    Then attribute $x has value: <value>
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x exists
    Then attribute $x has type: <attr>
    Then attribute $x has value type: <type>
    Then attribute $x has value: <value>
    Examples:
      | attr              | type       | value                              |
      | is-alive          | boolean    | true                               |
      | age               | long       | 21                                 |
      | score             | double     | 123.456                            |
      | name              | string     | alice                              |
      | birth-date        | datetime   | 1990-01-01 11:22:33                |
      | event-date        | datetimetz | 1990-01-01 11:22:33 Asia/Kathmandu |
      | schedule-interval | duration   | P1Y2M3DT4H5M6.789S                 |

  Scenario Outline: Attribute with value type <type> can be retrieved by its value
    When $x = attribute(<attr>) put instance with value: <value>
    Then attribute(<attr>) get instances contain: $x
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute(<attr>) get instances contain: $x
    Examples:
      | attr              | type       | value                              |
      | is-alive          | boolean    | true                               |
      | age               | long       | 21                                 |
      | score             | double     | 123.456                            |
      | name              | string     | alice                              |
      | birth-date        | datetime   | 1990-01-01 11:22:33                |
      | event-date        | datetimetz | 1990-01-01 11:22:33 Asia/Kathmandu |
      | schedule-interval | duration   | P1Y2M3DT4H5M6.789S                 |

  Scenario Outline: Attribute with value type <type> can be deleted
    When $x = attribute(<attr>) put instance with value: <value>
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When $x = attribute(<attr>) put instance with value: <value>
    When transaction commits
    When connection opens write transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When transaction commits
    When connection opens read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    Examples:
      | attr              | type       | value                              |
      | is-alive          | boolean    | true                               |
      | age               | long       | 21                                 |
      | score             | double     | 123.456                            |
      | name              | string     | alice                              |
      | birth-date        | datetime   | 1990-01-01 11:22:33                |
      | event-date        | datetimetz | 1990-01-01 11:22:33 Asia/Kathmandu |
      | schedule-interval | duration   | P1Y2M3DT4H5M6.789S                 |

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

  Scenario: Dependent attribute is not inserted
    Given transaction commits

    When connection opens schema transaction for database: typedb
    When put attribute type: ephemeral
    When attribute(ephemeral) set value-type: long
    When transaction commits

    When connection opens write transaction for database: typedb
    When $x = attribute(ephemeral) put instance with value: 1337
    Then transaction commits

    When connection opens read transaction for database: typedb
    When $x = attribute(ephemeral) get instance with value: 1337
    Then attribute $x does not exist
    # FIXME: read transactions shouldn't commit
    When transaction commits

    When connection opens schema transaction for database: typedb
    When attribute(ephemeral) set annotation: @independent
    When transaction commits

    When connection opens read transaction for database: typedb
    When $x = attribute(ephemeral) get instance with value: 1337
    Then attribute $x does not exist

