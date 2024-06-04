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
      | string     |
      | boolean    |
      | datetime   |
      # TODO: Add new value types

  Scenario: Entity types can own attributes of struct value types
    # TODO: Create structs in concept api
    When put struct type: passport-document(first-name: string, surname: string, birthday: datetime)
    When put attribute type: passport
    When attribute(passport) set value-type: passport-document
    When put entity type: person
    When entity(person) set owns: passport
    Then entity(person) get owns contain: passport
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns contain: passport

  Scenario: Entity types can not own entities, relations, roles, and structs
    When put entity type: car
    When put relation type: credit
    When relation(marriage) create role: creditor
    # TODO: Create structs in concept api
    When put struct type: passport(first-name: string, surname: string, birthday: datetime)
    When put entity type: person
    When entity(person) set owns: car; fails
    When entity(person) set owns: credit; fails
    When entity(person) set owns: creditor; fails
    When entity(person) set owns: passport; fails
    # TODO: Struct component? // Then entity(person) set owns: birthday; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario Outline: Relation types can own attributes of scalar value types
    When put attribute type: license
    When attribute(license) set value-type: <value-type>
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license; fails
    Then relation(marriage) get owns contain: license
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain: license
    Examples:
      | value-type |
      | long       |
      | double     |
      | string     |
      | boolean    |
      | datetime   |

  Scenario: Relation types can own attributes of struct value types
    # TODO: Create structs in concept api
    When put struct type: passport-document(first-name: string, surname: string, birthday: datetime)
    When put attribute type: passport
    When attribute(passport) set value-type: passport-document
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: passport
    Then relation(marriage) get owns contain: passport
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain: passport

  Scenario: Relation types can not own entities, relations, roles, and structs
    When put entity type: person
    When put relation type: credit
    When relation(marriage) create role: creditor
    When put relation type: marriage
    When relation(marriage) create role: spouse
    # TODO: Create structs in concept api
    When put struct type: passport(first-name: string, surname: string, birthday: datetime)
    When relation(marriage) set owns: person; fails
    When relation(marriage) set owns: credit; fails
    When relation(marriage) set owns: creditor; fails
    When relation(marriage) set owns: passport; fails
    # TODO: Struct component? // Then relation(marriage) set owns: birthday; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns is empty

  Scenario: Attribute types can not own entities, attributes, relations, roles, and structs
    When put entity type: person
    When put attribute type: surname
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport(first-name: string, surname: string, birthday: datetime)
    When put attribute type: name
    When attribute(name) set value-type: string
    Then attribute(name) set owns: person; fails
    Then attribute(name) set owns: surname; fails
    Then attribute(name) set owns: marriage; fails
    Then attribute(name) set owns: spouse; fails
    Then attribute(name) set owns: passport; fails
    # TODO: Struct component? // Then attribute(name) set owns: birthday; fails
    Then attribute(name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(name) get owns is empty

  Scenario: Struct types can not own entities, attributes, relations, roles, and structs
    When put entity type: person
    When put attribute type: name
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When attribute(surname) set value-type: string
    # TODO: Create structs in concept api
    When put struct type: passport(first-name: string, surname: string, birthday: datetime)
    # TODO: Create structs in concept api
    When put struct type: wallet(currency: string, value: double)
    Then struct(wallet) set owns: person; fails
    Then struct(wallet) set owns: name; fails
    Then struct(wallet) set owns: marriage; fails
    Then struct(wallet) set owns: spouse; fails
    Then struct(wallet) set owns: passport; fails
    # TODO: Struct component? // Then struct(wallet) set owns: birthday; fails
    Then struct(wallet) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then struct(wallet) get owns is empty

    # @values
  # TODO: Do we need tests for "plays", etc. to test that @values can not be applied there?
  Scenario Outline: Owns can have @values annotation for long value type
    When put entity type: player
    When put attribute type: rank
    When attribute(rank) set value-type: long
    When entity(player) set owns: rank
    When entity(player) get owns: rank, set annotation: @values(<args>)
    Then entity(player) get owns: rank; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: rank; get annotations contain: @values(<args>)
      # TODO: Will the args in `get @values(<args>)` be ordered? Maybe we need to check it through "contains" and change the `Concept API` to get args from annotations?..
    Examples:
      | args                                                                                                                                                                                                                                                                                                                                                                                                 |
      | 0                                                                                                                                                                                                                                                                                                                                                                                                    |
      | 1                                                                                                                                                                                                                                                                                                                                                                                                    |
      | -1                                                                                                                                                                                                                                                                                                                                                                                                   |
      | 1, 2                                                                                                                                                                                                                                                                                                                                                                                                 |
      | -9223372036854775808, 9223372036854775807                                                                                                                                                                                                                                                                                                                                                            |
      | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456                                                                                                                                                                                                                                                                                                                                              |
      | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 |

  Scenario Outline: Owns can have @values annotation for string value type
    When put entity type: player
    When put attribute type: rank
    When attribute(rank) set value-type: string
    When entity(player) set owns: rank
    When entity(player) get owns: rank, set annotation: @values(<args>)
    Then entity(player) get owns: rank; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: rank; get annotations contain: @values(<args>)
    Examples:
      | args                                                                                                                                        |
      | ""                                                                                                                                          |
      | "1"                                                                                                                                         |
      | "s", "S"                                                                                                                                    |
      | "This rank contains a sufficiently detailed description of its nature"                                                                      |
      | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                                                                                       |
      | "Rank with optional space", "Rank with optional space ", " Rank with optional space", "Rankwithoptionalspace", "Rank with optional space  " |

  Scenario Outline: Owns can have @values annotation for boolean value type
    When put entity type: player
    When put attribute type: verified
    When attribute(verified) set value-type: boolean
    When entity(player) set owns: verified
    When entity(player) get owns: verified, set annotation: @values(<args>)
    Then entity(player) get owns: verified; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: verified; get annotations contain: @values(<args>)
    Examples:
      | args        |
      | true        |
      | false       |
      | false, true |

  Scenario Outline: Owns can have @values annotation for double value type
    When put entity type: player
    When put attribute type: balance
    When attribute(balance) set value-type: double
    When entity(player) set owns: balance
    When entity(player) get owns: balance, set annotation: @values(<args>)
    Then entity(player) get owns: balance; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: balance; get annotations contain: @values(<args>)
    Examples:
      | args                                                                                  |
      | 0.0                                                                                   |
      | 0                                                                                     |
      | 1.1                                                                                   |
      | -2.45                                                                                 |
      | -3.444, 3.445                                                                         |
      | 0.00001, 0.0001, 0.001, 0.01                                                          |
      | -333.553, 33895, 98984.4555, 902394.44, 1000000000, 0.00001, 0.3, 3.14159265358979323 |

  Scenario Outline: Owns can have @values annotation for datetime value type
    When put entity type: player
    When put attribute type: registration-datetime
    When attribute(registration-datetime) set value-type: datetime
    When entity(player) set owns: registration-datetime
    When entity(player) get owns: registration-datetime, set annotation: @values(<args>)
    Then entity(player) get owns: registration-datetime; get annotations contain: @values(<args>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: registration-datetime; get annotations contain: @values(<args>)
    Examples:
      | args                                                                                                                      |
      | 2024-06-04                                                                                                                |
      | 2024-06-04T16:35                                                                                                          |
      | 2024-06-04T16:35:02                                                                                                       |
      | 2024-06-04T16:35:02.1                                                                                                     |
      | 2024-06-04T16:35:02.10                                                                                                    |
      | 2024-06-04T16:35:02.103                                                                                                   |
      | 2024-06-04, 2024-06-04T16:35, 2024-06-04T16:35:02, 2024-06-04T16:35:02.1, 2024-06-04T16:35:02.10, 2024-06-04T16:35:02.103 |

    # TODO: Add tests for new value types

  Scenario Outline: Owns can not have @values annotation with empty args
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(person) set owns: custom-field
    When entity(person) get owns: custom-field, set annotation: @values(); fails
    Then entity(person) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type |
      | long       |
      | double     |
      | string     |
      | boolean    |
      | datetime   |
      # TODO: Add new value types

  Scenario Outline: Owns can not have @values annotation with args of type different from attribute value-type
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(player) set owns: custom-field
    When entity(player) get owns: custom-field, set annotation: @values(<args>); fails
    Then entity(player) get owns: custom-field; get annotations is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: custom-field; get get annotations is empty
    Examples:
      | value-type | args       |
      | long       | 0.1        |
      | long       | "string"   |
      | long       | true       |
      | long       | 2024-06-04 |
      | double     | "string"   |
      | double     | true       |
      | double     | 2024-06-04 |
      | string     | 123        |
      | string     | true       |
      | string     | 2024-06-04 |
      | boolean    | 123        |
      | boolean    | "string"   |
      | boolean    | 2024-06-04 |
      | datetime   | 123        |
      | datetime   | "string"   |
      | datetime   | true       |

  Scenario Outline: Owns can not have @values annotation with duplicated args
    When put entity type: person
    When put attribute type: custom-field
    When attribute(custom-field) set value-type: <value-type>
    When entity(player) set owns: custom-field
    When entity(player) get owns: custom-field, set annotation: @values(<arg0>, <arg1>, <arg2>); fails
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
      | string     | "stringwithoutdifferences"  | "stringwithoutdifferences"   | "stringWITHdifferences"      |
      | string     | "stringwithoutdifferences " | "stringwithoutdifferences  " | "stringwithoutdifferences  " |
      | boolean    | true                        | true                         | false                        |
      | datetime   | 2024-06-04T16:35:02.101     | 2024-06-04T16:35:02.101      | 2024-06-04                   |
      | datetime   | 2020-06-04T16:35:02.10      | 2025-06-05T16:35             | 2025-06-05T16:35             |

    # TODO: Add owns of attributes with structs and this annotation
