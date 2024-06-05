# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    # TODO: "open" or "opens"?
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    # TODO: "create" or "createS"?
    Given connection create database: typedb
    # TODO: "open" or "opens"?
    Given connection opens schema transaction for database: typedb

  Scenario Outline: Entity types can own attributes of scalar value types
    When put attribute type: username
    When attribute(username) set value-type: <value-type>
    When put entity type: person
    When entity(person) set owns: username
    Then entity(person) get owns contain: username
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns contain: username
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario: Entity types can own attributes of struct value types
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport-document
    When struct(passport-document) create component: first-name
    When struct(passport-document) get component(first-name); set value-type: string
    When struct(passport-document) create component: surname
    When struct(passport-document) get component(surname); set value-type: string
    When struct(passport-document) create component: birthday
    When struct(passport-document) get component(birthday); set value-type: datetime
    When put attribute type: passport
    When attribute(passport) set value-type: passport-document
    When put entity type: person
    When entity(person) set owns: passport
    Then entity(person) get owns contain: passport
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns contain: passport

  Scenario: Entity types can not own entities, relations, roles, structs, and structs components
    When put entity type: car
    When put relation type: credit
    When relation(marriage) create role: creditor
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport
    When struct(passport) create component: first-name
    When struct(passport) get component(first-name); set value-type: string
    When struct(passport) create component: surname
    When struct(passport) get component(surname); set value-type: string
    When struct(passport) create component: birthday
    When struct(passport) get component(birthday); set value-type: datetime
    When put entity type: person
    Then entity(person) set owns: car; fails
    Then entity(person) set owns: credit; fails
    Then entity(person) set owns: marriage:creditor; fails
    Then entity(person) set owns: passport; fails
    Then entity(person) set owns: passport:birthday; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario Outline: Relation types can own attributes of scalar value types
    When put attribute type: license
    When attribute(license) set value-type: <value-type>
    When put relation type: marriage
    When relation(marriage) create role: spouse
    Then relation(marriage) set owns: license; fails
    Then relation(marriage) get owns contain: license
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain: license
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario: Relation types can own attributes of struct value types
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport-document
    When struct(passport-document) create component: first-name
    When struct(passport-document) get component(first-name); set value-type: string
    When struct(passport-document) create component: surname
    When struct(passport-document) get component(surname); set value-type: string
    When struct(passport-document) create component: birthday
    When struct(passport-document) get component(birthday); set value-type: datetime
    When put attribute type: passport
    When attribute(passport) set value-type: passport-document
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: passport
    Then relation(marriage) get owns contain: passport
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain: passport

  Scenario: Relation types can not own entities, relations, roles, structs, and structs components
    When put entity type: person
    When put relation type: credit
    When relation(marriage) create role: creditor
    When put relation type: marriage
    When relation(marriage) create role: spouse
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport-document
    When struct(passport-document) create component: first-name
    When struct(passport-document) get component(first-name); set value-type: string
    When struct(passport-document) create component: surname
    When struct(passport-document) get component(surname); set value-type: string
    When struct(passport-document) create component: birthday
    When struct(passport-document) get component(birthday); set value-type: datetime
    Then relation(marriage) set owns: person; fails
    Then relation(marriage) set owns: credit; fails
    Then relation(marriage) set owns: marriage:creditor; fails
    Then relation(marriage) set owns: passport; fails
    Then relation(marriage) set owns: passport:birthday; fails
    Then relation(marriage) set owns: marriage:spouse; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns is empty

  Scenario: Attribute types can not own entities, attributes, relations, roles, structs, and structs components
    When put entity type: person
    When put attribute type: surname
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport
    When struct(passport) create component: first-name
    When struct(passport) get component(first-name); set value-type: string
    When struct(passport) create component: surname
    When struct(passport) get component(surname); set value-type: string
    When struct(passport) create component: birthday
    When struct(passport) get component(birthday); set value-type: datetime
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set owns: person; fails
    Then attribute(name) set owns: surname; fails
    Then attribute(name) set owns: marriage; fails
    Then attribute(name) set owns: marriage:spouse; fails
    Then attribute(name) set owns: passport; fails
    Then attribute(name) set owns: passport:birthday; fails
    Then attribute(name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) get owns is empty

  Scenario: Struct types can not own entities, attributes, relations, roles, structs, and structs components
    When put entity type: person
    When put attribute type: name
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: passport
    When struct(passport) create component: first-name
    When struct(passport) get component(first-name); set value-type: string
    When struct(passport) create component: surname
    When struct(passport) get component(surname); set value-type: string
    When struct(passport) create component: birthday
    When struct(passport) get component(birthday); set value-type: datetime
    # TODO: Create structs in concept api (components or members or ... ?)
    When put struct type: wallet
    When struct(wallet) create component: currency
    When struct(wallet) get component(currency); set value-type: string
    When struct(wallet) create component: value
    When struct(wallet) get component(value); set value-type: double
    Then struct(wallet) set owns: person; fails
    Then struct(wallet) set owns: name; fails
    Then struct(wallet) set owns: marriage; fails
    Then struct(wallet) set owns: marriage:spouse; fails
    Then struct(wallet) set owns: passport; fails
    Then struct(wallet) set owns: passport:birthday; fails
    Then struct(wallet) set owns: wallet:currency; fails
    Then struct(wallet) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then struct(wallet) get owns is empty

#################
# @values
#################

  # TODO: Do we need tests for "plays", etc. to test that @values can not be applied there? Yes, will need to add non-suitable annotations tests everywhere!!!!

  Scenario Outline: Owns can have @values annotation for <value-type> value type
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When entity(person) get owns: custom-field, set annotation: @values(<args>)
    Then entity(person) get owns: custom-field; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-field; get annotations contain: @values(<args>)
      # TODO: Will the args in `get @values(<args>)` be ordered? Maybe we need to check it through "contains" and change the `Concept API` to get args from annotations?..
    Examples:
      | value-type | args                                                                                                                                                                                                                                                                                                                                                                                                 |
      | long       | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | long       | 1                                                                                                                                                                                                                                                                                                                                                                                                    |
      | long       | -1                                                                                                                                                                                                                                                                                                                                                                                                   |
      | long       | 1, 2                                                                                                                                                                                                                                                                                                                                                                                                 |
      | long       | -9223372036854775808, 9223372036854775807                                                                                                                                                                                                                                                                                                                                                            |
      | long       | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456                                                                                                                                                                                                                                                                                                                                              |
      | long       | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 |
      | string     | ""                                                                                                                                                                                                                                                                                                                                                                                                   |
      | string     | "1"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string     | "福"                                                                                                                                                                                                                                                                                                                                                                                                  |
      | string     | "s", "S"                                                                                                                                                                                                                                                                                                                                                                                             |
      | string     | "This rank contains a sufficiently detailed description of its nature"                                                                                                                                                                                                                                                                                                                               |
      | string     | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                                                                                                                                                                                                                                                                                                                                                |
      | string     | "Rank with optional space", "Rank with optional space ", " Rank with optional space", "Rankwithoptionalspace", "Rank with optional space  "                                                                                                                                                                                                                                                          |
      | boolean    | true                                                                                                                                                                                                                                                                                                                                                                                                 |
      | boolean    | false                                                                                                                                                                                                                                                                                                                                                                                                |
      | boolean    | false, true                                                                                                                                                                                                                                                                                                                                                                                          |
      | double     | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double     | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | double     | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
      | double     | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
      | double     | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
      | double     | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
      | double     | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
      | decimal    | 0.0                                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal    | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | decimal    | 1.1                                                                                                                                                                                                                                                                                                                                                                                                  |
      | decimal    | -2.45                                                                                                                                                                                                                                                                                                                                                                                                |
      | decimal    | -3.444, 3.445                                                                                                                                                                                                                                                                                                                                                                                        |
      | decimal    | 0.00001, 0.0001, 0.001, 0.01                                                                                                                                                                                                                                                                                                                                                                         |
      | decimal    | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323                                                                                                                                                                                                                                                                                                                |
      | datetime   | 2024-06-04                                                                                                                                                                                                                                                                                                                                                                                           |
      | datetime   | 2024-06-04T16:35                                                                                                                                                                                                                                                                                                                                                                                     |
      | datetime   | 2024-06-04T16:35:02                                                                                                                                                                                                                                                                                                                                                                                  |
      | datetime   | 2024-06-04T16:35:02.1                                                                                                                                                                                                                                                                                                                                                                                |
      | datetime   | 2024-06-04T16:35:02.10                                                                                                                                                                                                                                                                                                                                                                               |
      | datetime   | 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                                                                                                                              |
      | datetime   | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.1, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103                                                                                                                                                                                                                                                                            |
      | datetimetz | 2024-06-04+0000                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetimetz | 2024-06-04 Asia/Kathmandu                                                                                                                                                                                                                                                                                                                                                                            |
      | datetimetz | 2024-06-04+0100                                                                                                                                                                                                                                                                                                                                                                                      |
      | datetimetz | 2024-06-04T16:35+0100                                                                                                                                                                                                                                                                                                                                                                                |
      | datetimetz | 2024-06-04T16:35:02+0100                                                                                                                                                                                                                                                                                                                                                                             |
      | datetimetz | 2024-06-04T16:35:02.1+0100                                                                                                                                                                                                                                                                                                                                                                           |
      | datetimetz | 2024-06-04T16:35:02.10+0100                                                                                                                                                                                                                                                                                                                                                                          |
      | datetimetz | 2024-06-04T16:35:02.103+0100                                                                                                                                                                                                                                                                                                                                                                         |
      | datetimetz | 2024-06-04+0001, 2024-06-04 Asia/Kathmandu, 2024-06-04+0002, 2024-06-04+0010, 2024-06-04+0100, 2024-06-04-0100, 2024-06-04T16:35-0100, 2024-06-04T16:35:02+0200, 2024-06-04T16:35:02.1-0300, 2024-06-04T16:35:02.10+1000, 2024-06-04T16:35:02.103+0011                                                                                                                                               |
      | duration   | P1Y                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration   | P2M                                                                                                                                                                                                                                                                                                                                                                                                  |
      | duration   | P1Y2M                                                                                                                                                                                                                                                                                                                                                                                                |
      | duration   | P1Y2M3D                                                                                                                                                                                                                                                                                                                                                                                              |
      | duration   | P1Y2M3DT4H                                                                                                                                                                                                                                                                                                                                                                                           |
      | duration   | P1Y2M3DT4H5M                                                                                                                                                                                                                                                                                                                                                                                         |
      | duration   | P1Y2M3DT4H5M6S                                                                                                                                                                                                                                                                                                                                                                                       |
      | duration   | P1Y2M3DT4H5M6.789S                                                                                                                                                                                                                                                                                                                                                                                   |
      | duration   | P1Y, P1Y1M, P1Y1M1D, P1Y1M1DT1H, P1Y1M1DT1H1M, P1Y1M1DT1H1M1S, 1Y1M1DT1H1M1S0.1S, 1Y1M1DT1H1M1S0.001S, 1Y1M1DT1H1M0.000001S                                                                                                                                                                                                                                                                          |

  Scenario: Owns can have @values annotation for struct value type
    # TODO: Do we want to have it? If we do, add it to other Scenario Outlines with different value types

  Scenario Outline: Owns can not have @values annotation with empty args
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    Then entity(person) get owns: custom-field, set annotation: @values(); fails
    Then entity(person) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type |
      | long       |
      | double     |
      | decimal    |
      | string     |
      | boolean    |
      | datetime   |
      | datetimetz |
      | duration   |

  Scenario Outline: Owns can not have @values annotation for <value-type> value type with args of invalid value or type
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(player) set owns: custom-field
    Then entity(player) get owns: custom-field, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type | args                            |
      | long       | 0.1                             |
      | long       | "string"                        |
      | long       | true                            |
      | long       | 2024-06-04                      |
      | long       | 2024-06-04+0010                 |
      | double     | "string"                        |
      | double     | true                            |
      | double     | 2024-06-04                      |
      | double     | 2024-06-04+0010                 |
      | decimal    | "string"                        |
      | decimal    | true                            |
      | decimal    | 2024-06-04                      |
      | decimal    | 2024-06-04+0010                 |
      | string     | 123                             |
      | string     | true                            |
      | string     | 2024-06-04                      |
      | string     | 2024-06-04+0010                 |
      | string     | 'notstring'                     |
      | boolean    | 123                             |
      | boolean    | "string"                        |
      | boolean    | 2024-06-04                      |
      | boolean    | 2024-06-04+0010                 |
      | boolean    | truefalse                       |
      | datetime   | 123                             |
      | datetime   | "string"                        |
      | datetime   | true                            |
      | datetime   | 2024-06-04+0010                 |
      | datetimetz | 123                             |
      | datetimetz | "string"                        |
      | datetimetz | true                            |
      | datetimetz | 2024-06-04                      |
      | datetimetz | 2024-06-04 NotRealTimeZone/Zone |
      | duration   | 123                             |
      | duration   | "string"                        |
      | duration   | true                            |
      | duration   | 2024-06-04                      |
      | duration   | 2024-06-04+0100                 |
      | duration   | 1Y                              |
      | duration   | year                            |

  Scenario Outline: Owns can not have @values annotation for <value-type> value type with duplicated args
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(player) set owns: custom-field
    Then entity(player) get owns: custom-field, set annotation: @values(<arg0>, <arg1>, <arg2>); fails
    Then entity(player) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type | arg0                        | arg1                         | arg2                         |
      | long       | 1                           | 1                            | 1                            |
      | long       | 1                           | 1                            | 2                            |
      | long       | 1                           | 2                            | 1                            |
      | long       | 1                           | 2                            | 2                            |
      | double     | 0.1                         | 0.0001                       | 0.0001                       |
      | decimal    | 0.1                         | 0.0001                       | 0.0001                       |
      | string     | "stringwithoutdifferences"  | "stringwithoutdifferences"   | "stringWITHdifferences"      |
      | string     | "stringwithoutdifferences " | "stringwithoutdifferences  " | "stringwithoutdifferences  " |
      | boolean    | true                        | true                         | false                        |
      | datetime   | 2024-06-04T16:35:02.101     | 2024-06-04T16:35:02.101      | 2024-06-04                   |
      | datetime   | 2020-06-04T16:35:02.10      | 2025-06-05T16:35             | 2025-06-05T16:35             |
      | datetimetz | 2020-06-04T16:35:02.10+0100 | 2020-06-04T16:35:02.10+0000  | 2020-06-04T16:35:02.10+0100  |
      | duration   | P1Y1M                       | P1Y1M                        | P1Y2M                        |

  Scenario Outline: Owns-related @values annotation for <value-type> value type can be inherited and overridden by a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When put attribute type: second-custom-field
    When attribute(second-custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When relation(contract) set owns: custom-field
    When entity(person) set owns: second-custom-field
    When relation(contract) set owns: second-custom-field
    When entity(person) get owns: custom-field, set annotation: @values(<args>)
    When relation(contract) get owns: custom-field, set annotation: @values(<args>)
    Then entity(person) get owns: custom-field; get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-field; get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-field, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-field, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-field; get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-field; get annotations contain: @values(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns contain: custom-field
    Then relation(marriage) get owns contain: custom-field
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args>)
    Then entity(player) get owns contain: second-custom-field
    Then relation(marriage) get owns contain: second-custom-field
    # TODO: Overrides? Remove second-custom-field from test if we remove overrides!
    When entity(player) get owns: second-custom-field; set override: overridden-custom-field
    When relation(marriage) get owns: second-custom-field; set override: overridden-custom-field
    Then entity(player) get owns do not contain: second-custom-field
    Then relation(marriage) get owns do not contain: second-custom-field
    Then entity(player) get owns contain: overridden-custom-field
    Then relation(marriage) get owns contain: overridden-custom-field
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    When entity(player) get owns: custom-field, set annotation: @values(<args-override>)
    When relation(marriage) get owns: custom-field, set annotation: @values(<args-override>)
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args-override>)
    When entity(player) get owns: overridden-custom-field, set annotation: @values(<args-override>)
    When relation(marriage) get owns: overridden-custom-field, set annotation: @values(<args-override>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args-override>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args-override>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args-override>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args-override>)
    Examples:
      | value-type | args                                                                         | args-override                              |
      | long       | 1, 10, 20, 30                                                                | 10, 30                                     |
      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.0                                        |
      | decimal    | 0.0, 1.0                                                                     | 0.0                                        |
      | string     | "john", "John", "Johnny", "johnny"                                           | "John", "Johnny"                           |
      | boolean    | true, false                                                                  | true                                       |
      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2024-06-04, 2024-06-06                     |
      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Asia/Kathmandu, 2024-06-05+0010 |
      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P6M, P1Y3M, P1Y4M, P1Y6M                   |

  Scenario Outline: Inherited @values annotation on owns for <value-type> value type can not be overridden by the @values of same args or not a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When put attribute type: second-custom-field
    When attribute(second-custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When relation(contract) set owns: custom-field
    When entity(person) set owns: second-custom-field
    When relation(contract) set owns: second-custom-field
    When entity(person) get owns: custom-field, set annotation: @values(<args>)
    When relation(contract) get owns: custom-field, set annotation: @values(<args>)
    Then entity(person) get owns: custom-field; get annotations contain: @values(<args>)
    Then relation(contract) get owns: custom-field; get annotations contain: @values(<args>)
    When entity(person) get owns: second-custom-field, set annotation: @values(<args>)
    When relation(contract) get owns: second-custom-field, set annotation: @values(<args>)
    Then entity(person) get owns: second-custom-field; get annotations contain: @values(<args>)
    Then relation(contract) get owns: second-custom-field; get annotations contain: @values(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args>)
    # TODO: Overrides? Remove second-custom-field from test if we remove overrides!
    When entity(player) get owns: second-custom-field; set override: overridden-custom-field
    When relation(marriage) get owns: second-custom-field; set override: overridden-custom-field
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then entity(player) get owns: custom-field, set annotation: @values(<args>); fails
    Then relation(marriage) get owns: custom-field, set annotation: @values(<args>); fails
    Then entity(player) get owns: overridden-custom-field, set annotation: @values(<args>); fails
    Then relation(marriage) get owns: overridden-custom-field, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-field, set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns: custom-field, set annotation: @values(<args-override>); fails
    Then entity(player) get owns: overridden-custom-field, set annotation: @values(<args-override>); fails
    Then relation(marriage) get owns: overridden-custom-field, set annotation: @values(<args-override>); fails
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @values(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @values(<args>)
    Examples:
      | value-type | args                                                                         | args-override            |
      | long       | 1, 10, 20, 30                                                                | 10, 31                   |
      | double     | 1.0, 2.0, 3.0, 4.5                                                           | 2.001                    |
      | decimal    | 0.0, 1.0                                                                     | 0.01                     |
      | string     | "john", "John", "Johnny", "johnny"                                           | "Jonathan"               |
      | boolean    | false                                                                        | true                     |
      | datetime   | 2024-06-04, 2024-06-05, 2024-06-06                                           | 2020-06-04, 2020-06-06   |
      | datetimetz | 2024-06-04+0010, 2024-06-04 Asia/Kathmandu, 2024-06-05+0010, 2024-06-05+0100 | 2024-06-04 Europe/London |
      | duration   | P6M, P1Y, P1Y1M, P1Y2M, P1Y3M, P1Y4M, P1Y6M                                  | P3M, P1Y3M, P1Y4M, P1Y6M |

#################
# @range
#################

  Scenario Outline: Owns can have @range annotation for <value-type> value type in correct order
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    Then entity(player) get owns: custom-field, set annotation: @range(<arg1>, <arg0>); fails
    Then entity(person) get owns: custom-field; get annotations is empty
    When entity(person) get owns: custom-field, set annotation: @range(<arg0>, <arg1>)
    Then entity(person) get owns: custom-field; get annotations contain: @range(<arg0>, <arg1>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-field; get annotations contain: @range(<arg0>, <arg1>)
    Examples:
      | value-type | arg0                         | arg1                                                  |
      | long       | 0                            | 1                                                     |
      | long       | 1                            | 2                                                     |
      | long       | 0                            | 2                                                     |
      | long       | -1                           | 1                                                     |
      | long       | -9223372036854775808         | 9223372036854775807                                   |
      | string     | "A"                          | "a"                                                   |
      | string     | "a"                          | "z"                                                   |
      | string     | "A"                          | "福"                                                   |
      | string     | "AA"                         | "AAA"                                                 |
      | string     | "short string"               | "very-very-very-very-very-very-very-very long string" |
      | boolean    | false                        | true                                                  |
      | double     | 0.0                          | 0.0001                                                |
      | double     | 0.01                         | 1.0                                                   |
      | double     | 123.123                      | 123123123123.122                                      |
      | double     | -2.45                        | 2.45                                                  |
      | decimal    | 0.0                          | 0.0001                                                |
      | decimal    | 0.01                         | 1.0                                                   |
      | decimal    | 123.123                      | 123123123123.122                                      |
      | decimal    | -2.45                        | 2.45                                                  |
      | datetime   | 2024-06-04                   | 2024-06-05                                            |
      | datetime   | 2024-06-04                   | 2024-07-03                                            |
      | datetime   | 2024-06-04                   | 2025-01-01                                            |
      | datetime   | 1970-01-01                   | 9999-12-12                                            |
      | datetime   | 2024-06-04T16:35:02.10       | 2024-06-04T16:35:02.11                                |
      | datetimetz | 2024-06-04+0000              | 2024-06-05+0000                                       |
      | datetimetz | 2024-06-04+0100              | 2048-06-04+0100                                       |
      | datetimetz | 2024-06-04T16:35:02.103+0100 | 2024-06-04T16:35:02.104+0100                          |
      | datetimetz | 2024-06-04 Asia/Kathmandu    | 2024-06-05 Asia/Kathmandu                             |
      | duration   | P1Y                          | P2Y                                                   |
      | duration   | P2M                          | P1Y2M                                                 |
      | duration   | P1Y2M                        | P1Y2M3DT4H5M6.789S                                    |
      | duration   | P1Y2M3DT4H5M6.788S           | P1Y2M3DT4H5M6.789S                                    |

  Scenario: Owns can have @range annotation for struct value type
    # TODO: Do we want to have it? If we do, add it to other Scenario Outlines with different value types

  Scenario Outline: Owns can not have @range annotation for <value-type> value type with less than two args
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    Then entity(person) get owns: custom-field, set annotation: @range(); fails
    Then entity(person) get owns: custom-field, set annotation: @range(<arg0>); fails
    Then entity(person) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type | arg0            |
      | long       | 1               |
      | double     | 1.0             |
      | decimal    | 1.0             |
      | string     | "1"             |
      | boolean    | false           |
      | datetime   | 2024-06-04      |
      | datetimetz | 2024-06-04+0100 |
      | duration   | P1Y             |

    # TODO: If we allow arg0 == arg1, move this case to another test!
  Scenario Outline: Owns can not have @range annotation for <value-type> value type with invalid args or args number
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(player) set owns: custom-field
    Then entity(player) get owns: custom-field, set annotation: @range(<arg0>, <args>); fails
    Then entity(player) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type | arg0                            | args                                               |
      | long       | 1                               | 1                                                  |
      | long       | 1                               | 2, 3                                               |
      | long       | 1                               | "string"                                           |
      | long       | 1                               | 2, "string"                                        |
      | long       | 1                               | 2, "string", true, 2024-06-04, 55                  |
      | long       | "string"                        | 1                                                  |
      | long       | true                            | 1                                                  |
      | long       | 2024-06-04                      | 1                                                  |
      | long       | 2024-06-04+0010                 | 1                                                  |
      | double     | 1.0                             | 1.0                                                |
      | double     | 1.0                             | 2.0, 3.0                                           |
      | double     | 1.0                             | "string"                                           |
      | double     | "string"                        | 1.0                                                |
      | double     | true                            | 1.0                                                |
      | double     | 2024-06-04                      | 1.0                                                |
      | double     | 2024-06-04+0010                 | 1.0                                                |
      | decimal    | 1.0                             | 1.0                                                |
      | decimal    | 1.0                             | 2.0, 3.0                                           |
      | decimal    | 1.0                             | "string"                                           |
      | decimal    | "string"                        | 1.0                                                |
      | decimal    | true                            | 1.0                                                |
      | decimal    | 2024-06-04                      | 1.0                                                |
      | decimal    | 2024-06-04+0010                 | 1.0                                                |
      | string     | "123"                           | "123"                                              |
      | string     | "123"                           | "1234", "12345"                                    |
      | string     | "123"                           | 123                                                |
      | string     | 123                             | "123"                                              |
      | string     | true                            | "str"                                              |
      | string     | 2024-06-04                      | "str"                                              |
      | string     | 2024-06-04+0010                 | "str"                                              |
      | string     | 'notstring'                     | "str"                                              |
      | boolean    | false                           | false                                              |
      | boolean    | true                            | true                                               |
      | boolean    | true                            | 123                                                |
      | boolean    | 123                             | true                                               |
      | boolean    | "string"                        | true                                               |
      | boolean    | 2024-06-04                      | true                                               |
      | boolean    | 2024-06-04+0010                 | true                                               |
      | boolean    | truefalse                       | true                                               |
      | datetime   | 2030-06-04                      | 2030-06-04                                         |
      | datetime   | 2030-06-04                      | 2030-06-05, 2030-06-06                             |
      | datetime   | 2030-06-04                      | 123                                                |
      | datetime   | 123                             | 2030-06-04                                         |
      | datetime   | "string"                        | 2030-06-04                                         |
      | datetime   | true                            | 2030-06-04                                         |
      | datetime   | 2024-06-04+0010                 | 2030-06-04                                         |
      | datetimetz | 2030-06-04 Europe/London        | 2030-06-04 Europe/London                           |
      | datetimetz | 2030-06-04 Europe/London        | 2030-06-05 Europe/London, 2030-06-06 Europe/London |
      | datetimetz | 2030-06-05 Europe/London        | 123                                                |
      | datetimetz | 123                             | 2030-06-05 Europe/London                           |
      | datetimetz | "string"                        | 2030-06-05 Europe/London                           |
      | datetimetz | true                            | 2030-06-05 Europe/London                           |
      | datetimetz | 2024-06-04                      | 2030-06-05 Europe/London                           |
      | datetimetz | 2024-06-04 NotRealTimeZone/Zone | 2030-06-05 Europe/London                           |
      | duration   | P1Y                             | P1Y                                                |
      | duration   | P1Y                             | P2Y, P3Y                                           |
      | duration   | P1Y                             | 123                                                |
      | duration   | 123                             | P1Y                                                |
      | duration   | "string"                        | P1Y                                                |
      | duration   | true                            | P1Y                                                |
      | duration   | 2024-06-04                      | P1Y                                                |
      | duration   | 2024-06-04+0100                 | P1Y                                                |
      | duration   | 1Y                              | P1Y                                                |
      | duration   | year                            | P1Y                                                |

  Scenario Outline: Owns-related @range annotation for <value-type> value type can be inherited and overridden by a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When put attribute type: second-custom-field
    When attribute(second-custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When relation(contract) set owns: custom-field
    When entity(person) set owns: second-custom-field
    When relation(contract) set owns: second-custom-field
    When entity(person) get owns: custom-field, set annotation: @range(<args>)
    When relation(contract) get owns: custom-field, set annotation: @range(<args>)
    Then entity(person) get owns: custom-field; get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-field; get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-field, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-field, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-field; get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-field; get annotations contain: @range(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns contain: custom-field
    Then relation(marriage) get owns contain: custom-field
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args>)
    Then entity(player) get owns contain: second-custom-field
    Then relation(marriage) get owns contain: second-custom-field
    # TODO: Overrides? Remove second-custom-field from test if we remove overrides!
    When entity(player) get owns: second-custom-field; set override: overridden-custom-field
    When relation(marriage) get owns: second-custom-field; set override: overridden-custom-field
    Then entity(player) get owns do not contain: second-custom-field
    Then relation(marriage) get owns do not contain: second-custom-field
    Then entity(player) get owns contain: overridden-custom-field
    Then relation(marriage) get owns contain: overridden-custom-field
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    When entity(player) get owns: custom-field, set annotation: @range(<args-override>)
    When relation(marriage) get owns: custom-field, set annotation: @range(<args-override>)
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args-override>)
    When entity(player) get owns: overridden-custom-field, set annotation: @range(<args-override>)
    When relation(marriage) get owns: overridden-custom-field, set annotation: @range(<args-override>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args-override>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args-override>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args-override>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args-override>)
    Examples:
      | value-type | args                             | args-override                             |
      | long       | 1, 10                            | 1, 5                                      |
      | double     | 1.0, 10.0                        | 2.0, 10.0                                 |
      | decimal    | 0.0, 1.0                         | 0.0, 0.999999                             |
      | string     | "A", "Z"                         | "J", "Z"                                  |
      | datetime   | 2024-06-04, 2024-06-05           | 2024-06-04, 2024-06-04T12:00:00           |
      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-04T12:00:00+0010 |
      | duration   | P6M, P1Y                         | P8M, P9M                                  |

  Scenario Outline: Inherited @range annotation on owns for <value-type> value type can not be overridden by the @range of same args or not a subset of args
    When put entity type: person
    When put relation type: contract
    When relation(contract) create role: participant
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When put attribute type: second-custom-field
    When attribute(second-custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When relation(contract) set owns: custom-field
    When entity(person) set owns: second-custom-field
    When relation(contract) set owns: second-custom-field
    When entity(person) get owns: custom-field, set annotation: @range(<args>)
    When relation(contract) get owns: custom-field, set annotation: @range(<args>)
    Then entity(person) get owns: custom-field; get annotations contain: @range(<args>)
    Then relation(contract) get owns: custom-field; get annotations contain: @range(<args>)
    When entity(person) get owns: second-custom-field, set annotation: @range(<args>)
    When relation(contract) get owns: second-custom-field, set annotation: @range(<args>)
    Then entity(person) get owns: second-custom-field; get annotations contain: @range(<args>)
    Then relation(contract) get owns: second-custom-field; get annotations contain: @range(<args>)
    When put entity type: player
    When put relation type: marriage
    When entity(player) set supertype: person
    When relation(marriage) set supertype: contract
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args>)
    # TODO: Overrides? Remove second-custom-field from test if we remove overrides!
    When entity(player) get owns: second-custom-field; set override: overridden-custom-field
    When relation(marriage) get owns: second-custom-field; set override: overridden-custom-field
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then entity(player) get owns: custom-field, set annotation: @range(<args>); fails
    Then relation(marriage) get owns: custom-field, set annotation: @range(<args>); fails
    Then entity(player) get owns: overridden-custom-field, set annotation: @range(<args>); fails
    Then relation(marriage) get owns: overridden-custom-field, set annotation: @range(<args>); fails
    Then entity(player) get owns: custom-field, set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns: custom-field, set annotation: @range(<args-override>); fails
    Then entity(player) get owns: overridden-custom-field, set annotation: @range(<args-override>); fails
    Then relation(marriage) get owns: overridden-custom-field, set annotation: @range(<args-override>); fails
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    When transaction commits
    When connection opens schema transaction for database: typedb
    Then entity(player) get owns: custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: custom-field, get annotations contain: @range(<args>)
    Then entity(player) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Then relation(marriage) get owns: overridden-custom-field, get annotations contain: @range(<args>)
    Examples:
      | value-type | args                             | args-override                             |
      | long       | 1, 10                            | -1, 5                                     |
      | double     | 1.0, 10.0                        | 0.0, 150.0                                |
      | decimal    | 0.0, 1.0                         | -0.0001, 0.999999                         |
      | string     | "A", "Z"                         | "A", "z"                                  |
      | datetime   | 2024-06-04, 2024-06-05           | 2023-06-04, 2024-06-04T12:00:00           |
      | datetimetz | 2024-06-04+0010, 2024-06-05+0010 | 2024-06-04+0010, 2024-06-05T01:00:00+0010 |
      | duration   | P6M, P1Y                         | P8M, P1Y1D                                |
