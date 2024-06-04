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

    # Permutations: (entity, attribute, relation) owns (entity, attribute, relation)
  Scenario: Entity types can own attributes
    When put attribute type: username
    When attribute(username) set value-type: string
    When put entity type: person
    When entity(person) set owns: username
    Then entity(person) get owns contain: username
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns contain: username

  Scenario: Relation types can own attributes
    When put attribute type: license
    When attribute(license) set value-type: string
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: license; fails
    Then relation(marriage) get owns contain: license
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns contain: license

  Scenario: Attribute types can not own attributes
    When put attribute type: country-code
    When attribute(country-code) set value-type: string
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    Then attribute(country-name) set owns: country-code; fails
    Then attribute(country-name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(country-name) get owns is empty

  Scenario: Entity types can not own entities
    When put entity type: car
    When put entity type: person
    When entity(person) set owns: car; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario: Relation types can not own entities
    When put entity type: person
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: person; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns is empty

  Scenario: Attribute types can not own entities
    When put entity type: country
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    Then attribute(country-name) set owns: country; fails
    Then attribute(country-name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(country-name) get owns is empty

  Scenario: Entity types can not own relations and roles
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When put entity type: person
    When entity(person) set owns: marriage; fails
    When entity(person) set owns: spouse; fails
    Then entity(person) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(person) get owns is empty

  Scenario: Relation types can not own relations and roles
    When put relation type: credit
    When relation(marriage) create role: creditor
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When relation(marriage) set owns: credit; fails
    When relation(marriage) set owns: creditor; fails
    Then relation(marriage) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then relation(marriage) get owns is empty

    # TODO: Do we want to test all the existing things (roles, structs) this way?
    # TODO: Could we refactor it to have less "real" examples regarding namings, but write a Scenario Outline with
    # multiple types  (entity, relation, attribute) with the same names (like entity(marriage), relation(marriage), attribute(marriage))
  Scenario: Attribute types can not own relations and roles
    When put relation type: marriage
    When relation(marriage) create role: spouse
    When put attribute type: country-name
    When attribute(country-name) set value-type: string
    Then attribute(country-name) set owns: marriage; fails
    Then attribute(country-name) set owns: spouse; fails
    Then attribute(country-name) get owns is empty
    When transaction commits
    When connection opens read transaction for database: typedb
    Then attribute(country-name) get owns is empty

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
      # TODO: Will the args in `get @values(<args>)` be ordered?
    Examples:
      | args                                                    |
      | 0                                                       |
      | 1                                                       |
      | -1                                                      |
      | 1, 2                                                    |
      | -9223372036854775808, 9223372036854775807               |
      | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456 |
      # TODO: Do we have args numbers limit? Do we want to test it?

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
      | args                                                                   |
      | ""                                                                     |
      | "1"                                                                    |
      | "s"                                                                    |
      | "This rank contains a sufficiently detailed description of its nature" |
      | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                  |

    # TODO: Maybe it should be restricted!
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

    # TODO: Maybe it should be restricted!
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
    # TODO: What to do with doubles written as longs (without `.`)?
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