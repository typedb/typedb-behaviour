# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Attribute

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    # Write schema for the test scenarios
    Given create attribute type: is-alive
    Given attribute(is-alive) set value type: boolean
    Given attribute(is-alive) set annotation: @independent
    Given create attribute type: age
    Given attribute(age) set value type: integer
    Given attribute(age) set annotation: @independent
    Given create attribute type: score
    Given attribute(score) set value type: double
    Given attribute(score) set annotation: @independent
    Given create attribute type: birth-date
    Given attribute(birth-date) set value type: date
    Given attribute(birth-date) set annotation: @independent
    Given create attribute type: event-datetime
    Given attribute(event-datetime) set value type: datetime
    Given attribute(event-datetime) set annotation: @independent
    Given create attribute type: global-date
    Given attribute(global-date) set value type: datetime-tz
    Given attribute(global-date) set annotation: @independent
    Given create attribute type: schedule-interval
    Given attribute(schedule-interval) set value type: duration
    Given attribute(schedule-interval) set annotation: @independent
    Given create attribute type: name
    Given attribute(name) set value type: string
    Given attribute(name) set annotation: @independent
    Given create attribute type: email
    Given attribute(email) set value type: string
    Given attribute(email) set annotation: @independent
    Given attribute(email) set annotation: @regex("\S+@\S+\.\S+")
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given set time-zone: Europe/London

  Scenario Outline: Attribute with value type <type> can be created
    When $x = attribute(<attr>) put instance with value: <value>
    Then attribute $x exists
    Then attribute $x has type: <attr>
    Then attribute $x has value type: <type>
    Then attribute $x has value: <value>
    When transaction commits
    When connection open read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x exists
    Then attribute $x has type: <attr>
    Then attribute $x has value type: <type>
    Then attribute $x has value: <value>
    Examples:
      | attr              | type        | value                                                                              |
      | is-alive          | boolean     | true                                                                               |
      | age               | integer     | 21                                                                                 |
      | score             | double      | 123.456                                                                            |
      | name              | string      | alice                                                                              |
      | name              | string      | very-long-string-with_@strangESymßo¬s¡2)*(()˚¬ª#08uj!@%@£^%*&%(*@!_++±§≥≤<>?:😎資料庫 |
      | birth-date        | date        | 1990-01-01                                                                         |
      | event-datetime    | datetime    | 1990-01-01T11:22:33.123456789                                                      |
      | global-date       | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu                                                 |
      | global-date       | datetime-tz | 1990-01-01T11:22:33-0100                                                           |
      | global-date       | datetime-tz | 1990-01-01T11:22:33Z                                                               |
      | schedule-interval | duration    | P1Y2M3DT4H5M6.789S                                                                 |

  Scenario Outline: Attribute with value type <type> can be retrieved by its value
    When $x = attribute(<attr>) put instance with value: <value>
    Then attribute(<attr>) get instances contain: $x
    When transaction commits
    When connection open read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute(<attr>) get instances contain: $x
    Examples:
      | attr              | type        | value                                                                              |
      | is-alive          | boolean     | true                                                                               |
      | age               | integer     | 21                                                                                 |
      | score             | double      | 123.456                                                                            |
      | name              | string      | alice                                                                              |
      | name              | string      | very-long-string-with_@strangESymßo¬s¡2)*(()˚¬ª#08uj!@%@£^%*&%(*@!_++±§≥≤<>?:😎資料庫 |
      | birth-date        | date        | 1990-01-01                                                                         |
      | event-datetime    | datetime    | 1990-01-01T11:22:33.123456789                                                      |
      | global-date       | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu                                                 |
      | global-date       | datetime-tz | 1990-01-01T11:22:33-0100                                                           |
      | schedule-interval | duration    | P1Y2M3DT4H5M6.789S                                                                 |

  Scenario Outline: Attribute with value type <type> can be deleted
    When $x = attribute(<attr>) put instance with value: <value>
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When $x = attribute(<attr>) put instance with value: <value>
    When transaction commits
    When connection open write transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    When delete attribute: $x
    Then attribute $x is deleted: true
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    When transaction commits
    When connection open read transaction for database: typedb
    When $x = attribute(<attr>) get instance with value: <value>
    Then attribute $x does not exist
    Examples:
      | attr              | type        | value                              |
      | is-alive          | boolean     | true                               |
      | age               | integer     | 21                                 |
      | score             | double      | 123.456                            |
      | name              | string      | alice                              |
      | birth-date        | date        | 1990-01-01                         |
      | event-datetime    | datetime    | 1990-01-01T11:22:33.123456789      |
      | global-date       | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu |
      | global-date       | datetime-tz | 1990-01-01T11:22:33-0100           |
      | schedule-interval | duration    | P1Y2M3DT4H5M6.789S                 |

  Scenario: Attribute with value type string that satisfies the regular expression can be created
    When $x = attribute(email) put instance with value: alice@email.com
    Then attribute $x exists
    Then attribute $x has type: email
    Then attribute $x has value type: string
    Then attribute $x has value: alice@email.com
    When transaction commits
    When connection open read transaction for database: typedb
    When $x = attribute(email) get instance with value: alice@email.com
    Then attribute $x exists
    Then attribute $x has type: email
    Then attribute $x has value type: string
    Then attribute $x has value: alice@email.com

  Scenario: Attribute with value type string that does not satisfy the regular expression cannot be created
    When attribute(email) put instance with value: alice-email-com; fails

  Scenario: Datetime attribute can be inserted in one timezone and retrieved in another with no change in the value
    When set time-zone: Asia/Calcutta
    When $x = attribute(event-datetime) put instance with value: 2001-08-23T08:30:00
    Then attribute $x exists
    Then attribute $x has type: event-datetime
    Then attribute $x has value type: datetime
    Then attribute $x has value: 2001-08-23T08:30:00
    When transaction commits
    When connection open read transaction for database: typedb
    When set time-zone: America/Chicago
    When $x = attribute(event-datetime) get instance with value: 2001-08-23T08:30:00
    Then attribute $x exists
    Then attribute $x has type: event-datetime
    Then attribute $x has value type: datetime
    Then attribute $x has value: 2001-08-23T08:30:00

  Scenario: Dependent attribute is not inserted
    Given transaction commits

    When connection open schema transaction for database: typedb
    When create attribute type: ephemeral
    When attribute(ephemeral) set value type: integer
    When transaction commits

    When connection open write transaction for database: typedb
    When $x = attribute(ephemeral) put instance with value: 1337
    Then transaction commits

    When connection open read transaction for database: typedb
    When $x = attribute(ephemeral) get instance with value: 1337
    Then attribute $x does not exist
    When transaction closes

    When connection open schema transaction for database: typedb
    When attribute(ephemeral) set annotation: @independent
    When transaction commits

    When connection open read transaction for database: typedb
    When $x = attribute(ephemeral) get instance with value: 1337
    Then attribute $x does not exist

  Scenario: Cannot create instances of abstract attribute type
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: full-name
    When attribute(full-name) set value type: string
    When attribute(full-name) set annotation: @abstract
    When attribute(full-name) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(full-name) put instance with value: "bob"; fails
    When transaction closes
    When connection open schema transaction for database: typedb
    When attribute(full-name) unset annotation: @abstract
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(full-name) put instance with value: "bob"
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(full-name) get instances is not empty

  Scenario Outline: Cannot create instances of attribute type of value type <value-type> with values not matching @values(<values-args>) annotation
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: limited-value
    When attribute(limited-value) set value type: <value-type>
    When attribute(limited-value) set annotation: @values(<values-args>)
    When attribute(limited-value) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(limited-value) put instance with value: <fail-val>; fails
    Then attribute(limited-value) put instance with value: <suc-val>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(limited-value) get instances is not empty
    Then $suc = attribute(limited-value) get instance with value: <suc-val>
    Then $fail = attribute(limited-value) get instance with value: <fail-val>
    Then attribute $suc exists
    Then attribute $fail does not exist
    Examples:
      | value-type  | values-args                                     | fail-val                      | suc-val                       |
      | integer     | 1, 5, 4                                         | 2                             | 1                             |
      | integer     | 1                                               | 2                             | 1                             |
      | double      | 1.1, 1.5, 0.01                                  | 0.1                           | 0.01                          |
      | double      | 0.01                                            | 0.1                           | 0.01                          |
      | double      | 0.01, 0.0001                                    | 0.001                         | 0.0001                        |
      | double      | 0.01, 0.0001                                    | 1.0                           | 0.01                          |
      | decimal     | -8.0dec, 88.3dec, 0.001dec                      | 0.01dec                       | 0.001dec                      |
      | decimal     | 0.001dec                                        | 0.01dec                       | 0.001dec                      |
      | decimal     | 0.01dec                                         | 0.1dec                        | 0.01dec                       |
      | decimal     | 0.01dec, 0.0001dec                              | 0.001dec                      | 0.0001dec                     |
      | decimal     | 0.01dec, 0.0001dec                              | 1.0dec                        | 0.01dec                       |
      | string      | "s", "sss", "S"                                 | "ss"                          | "sss"                         |
      | string      | "s", "sss"                                      | "S"                           | "s"                           |
      | string      | "sss"                                           | "ss"                          | "sss"                         |
      | boolean     | true                                            | false                         | true                          |
      | boolean     | false                                           | true                          | false                         |
      | date        | 2024-05-05, 2024-05-07                          | 2024-05-06                    | 2024-05-05                    |
      | date        | 2024-05-05                                      | 2024-05-06                    | 2024-05-05                    |
      | datetime    | 2024-05-05T16:01:59, 2024-05-05T16:01:58        | 2024-05-05T16:01:57           | 2024-05-05T16:01:59           |
      | datetime    | 2024-05-05T16:01:59                             | 2024-05-05T16:01:57           | 2024-05-05T16:01:59           |
      | datetime    | 2024-05-05T16:01:59.123456789                   | 2024-05-05T16:01:57.12345678  | 2024-05-05T16:01:59.123456789 |
      | datetime    | 2024-05-05T16:01:59.123456789                   | 2024-05-05T16:01:57.123456788 | 2024-05-05T16:01:59.123456789 |
      | datetime    | 2024-05-05T16:01:59.123456789                   | 2024-05-05T16:01:57.12345679  | 2024-05-05T16:01:59.123456789 |
      | datetime-tz | 2024-05-05T00:00+0100, 2024-05-05T16:31:59+0100 | 2024-05-05T00:00:00+0000      | 2024-05-05T16:31:59+0100      |
      | datetime-tz | 2024-05-05T16:31:59+0100                        | 2024-05-05T00:00:00+0000      | 2024-05-05T16:31:59+0100      |
      | duration    | P1Y, P1Y5MT8H                                   | P2Y                           | P1Y                           |
      | duration    | P1Y                                             | P2Y                           | P1Y                           |
      | duration    | P1Y, P1Y1M1DT1H1M0.000001S                      | P1Y1M1DT1H1M0.00001S          | P1Y1M1DT1H1M0.000001S         |

  Scenario Outline: Cannot create instances of attribute type of value type <value-type> with values not matching @range(<range-args>) annotation
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: limited-value
    When attribute(limited-value) set value type: <value-type>
    When attribute(limited-value) set annotation: @range(<range-args>)
    When attribute(limited-value) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(limited-value) put instance with value: <fail-val>; fails
    Then attribute(limited-value) put instance with value: <suc-val>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(limited-value) get instances is not empty
    Then $suc = attribute(limited-value) get instance with value: <suc-val>
    Then $fail = attribute(limited-value) get instance with value: <fail-val>
    Then attribute $suc exists
    Then attribute $fail does not exist
    Examples:
      | value-type  | range-args                                                           | fail-val                          | suc-val                           |
      | integer     | 1..3                                                                 | 0                                 | 1                                 |
      | integer     | 1..3                                                                 | -1                                | 2                                 |
      | integer     | 1..3                                                                 | 4                                 | 3                                 |
      | integer     | -1..1                                                                | -2                                | 0                                 |
      | integer     | -1..1                                                                | 2                                 | -1                                |
      | double      | 0.01..0.1                                                            | 0.001                             | 0.01                              |
      | double      | 0.01..0.1                                                            | 0.11                              | 0.0111111                         |
      | double      | -0.01..0.1                                                           | -0.011                            | 0.01                              |
      | double      | -0.01..0.1                                                           | 0.11                              | -0.01                             |
      | double      | 19.337..339.0                                                        | 19.336                            | 78.838482823782                   |
      | decimal     | 0.01dec..0.1dec                                                      | 0.001dec                          | 0.01dec                           |
      | decimal     | 0.01dec..0.1dec                                                      | 0.11dec                           | 0.0111111dec                      |
      | decimal     | -0.01dec..0.1dec                                                     | -0.011dec                         | 0.01dec                           |
      | decimal     | -0.01dec..0.1dec                                                     | 0.11dec                           | -0.01dec                          |
      | decimal     | 19.337dec..339.0dec                                                  | 19.336dec                         | 78.838482823782dec                |
      | string      | "1".."3"                                                             | "0"                               | "1"                               |
      | string      | "1".."3"                                                             | "#"                               | "2"                               |
      | string      | "1".."3"                                                             | "4"                               | "3"                               |
      | string      | "s".."sss"                                                           | "S"                               | "s"                               |
      | string      | "s".."sss"                                                           | "j"                               | "ss"                              |
      | string      | "s".."sss"                                                           | "SSS"                             | "sss"                             |
      | date        | 2024-05-05..2024-05-07                                               | 2024-05-04                        | 2024-05-06                        |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59                             | 2024-05-04T16:01:59               | 2024-05-05T16:01:59               |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59                             | 2024-05-05T16:02:00               | 2024-05-05T16:01:58               |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59                             | 2025-05-05T16:01:58               | 2024-05-05T16:01:57               |
      | datetime-tz | 2024-05-05T00:00:00+0010..2024-05-05T16:31:59+0100                   | 2024-05-04T00:00+0000             | 2024-05-05T16:31:00+0100          |
      | datetime-tz | 2024-05-05T00:00:00+0010..2024-05-05T16:31:59+0100                   | 2024-05-05T00:00:00+0100          | 2024-05-05T00:00:00+0010          |
      | datetime-tz | 2024-05-05T00:00:00 Europe/Berlin..2024-05-05T00:00:00 Europe/London | 2024-05-05T00:00:01 Europe/London | 2024-05-05T00:00:01 Europe/Berlin |

  Scenario Outline: Attribute with <value-type> value type and @range(<range-args>) correctly validates <input-type> input values
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: ranged-attr
    When attribute(ranged-attr) set value type: <value-type>
    When attribute(ranged-attr) set annotation: @range(<range-args>)
    When attribute(ranged-attr) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(ranged-attr) put instance with value: <fail-val>; fails
    Then attribute(ranged-attr) put instance with value: <suc-val>
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(ranged-attr) get instances is not empty
    Then $suc = attribute(ranged-attr) get instance with value: <suc-val>
    Then $fail = attribute(ranged-attr) get instance with value: <fail-val>
    Then attribute $suc exists
    Then attribute $fail does not exist
    Examples:
      | value-type | range-args       | input-type | fail-val | suc-val |
      # double attribute with integer input values
      | double     | 0.0..100.0       | integer    | 150      | 50      |
      | double     | 0.0..100.0       | integer    | -10      | 0       |
      | double     | 0.0..100.0       | integer    | 101      | 100     |
      # double attribute with decimal input values
      | double     | 0.0..100.0       | decimal    | 150.5dec | 50.5dec |
      | double     | 0.0..100.0       | decimal    | -0.1dec  | 0.0dec  |
      # decimal attribute with integer input values
      | decimal    | 0.0dec..100.0dec | integer    | 150      | 50      |
      | decimal    | 0.0dec..100.0dec | integer    | -10      | 0       |
      | decimal    | 0.0dec..100.0dec | integer    | 101      | 100     |
       # TODO decimals and doubles don't go cleanly into integers, so that isn't allowed?
#      # decimal attribute with double input values
#      | decimal    | 0.0dec..100.0dec | double     | 150.5dec    | 50.5    |
#      | decimal    | 0.0dec..100.0dec | double     | -0.1dec     | 0.0     |
#      # integer attribute with double input values
#      | integer    | 0..100           | double     | 150.0    | 50.0    |
#      | integer    | 0..100           | double     | -10.0    | 0.0     |
#      # integer attribute with decimal input values
#      | integer    | 0..100           | decimal    | 150.0dec | 50.0dec |
#      | integer    | 0..100           | decimal    | -10.0dec | 0.0dec  |
