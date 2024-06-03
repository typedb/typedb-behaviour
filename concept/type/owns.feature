# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Owns

  Background:
    Given typedb starts
    Given connection opens with default authentication # TODO: "open" or "opens"?
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb # TODO: "create" or "createS"?
    Given connection opens schema transaction for database: typedb # TODO: "open" or "opens"?

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
  Scenario Outline: Owns can have @values annotation for long value type
    When put entity type: player
    When put attribute type: rank
    When attribute(rank) set value-type: long
    When entity(player) set owns: rank
    When entity(player) get owns: rank, set annotation: @values(<params>)
      |  |
      |  |
    Then entity(player) get owns: rank; get annotations contain: @values(<params>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: rank; get annotations contain: @values(<params>)
    Examples:
      | params                                                  |
      | 0                                                       |
      | 1                                                       |
      | -1                                                      |
      | 1, 2                                                    |
      | -9223372036854775808, 9223372036854775807               |
      | 2, 1, 3, 4, 5, 6, 7, 9, 10, 11, 55, -1, -654321, 123456 |

  Scenario Outline: Owns can have @values annotation for string value type
    When put entity type: player
    When put attribute type: rank
    When attribute(rank) set value-type: string
    When entity(player) set owns: rank
    When entity(player) get owns: rank, set annotation: @values(<params>)
      |  |
      |  |
    Then entity(player) get owns: rank; get annotations contain: @values(<params>)
    When transaction commits
    When connection opens read transaction for database: typedb
    Then entity(player) get owns: rank; get annotations contain: @values(<params>)
    Examples:
      | params                                                                 |
      | ""                                                                     |
      | "1"                                                                    |
      | "s"                                                                    |
      | "This rank contains a sufficiently detailed description of its nature" |
      | "Scout", "Stone Guard", "Stone Guard", "High Warlord"                  |